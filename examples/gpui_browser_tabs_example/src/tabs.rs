//! The windows, their tab lists, and Chrome-style tab dragging on top of
//! nativeapi's `WindowDragSession`.
//!
//! Everything after the press is driven by the native session's cursor
//! position, including reordering within a strip: once a tab has been merged
//! into another window, that window never saw the press, so GPUI has no mouse
//! events to report there.
//!
//! - In a strip, the tab follows the cursor horizontally and the others make
//!   room for it.
//! - Moving [`DETACH_MARGIN`] above or below the strip tears the tab off into
//!   a new window of the same size, with the tab still under the cursor. A
//!   window's only tab takes the whole window along instead.
//! - A torn-off window dragged over another window's strip merges into it at
//!   the cursor, and the drag carries on inside that strip.

use std::cell::Cell;
use std::collections::HashMap;
use std::rc::Rc;

use futures::channel::mpsc;
use futures::StreamExt;
use gpui::{
    point, px, size, AnyWindowHandle, App, AppContext, Bounds, Context, Entity, Pixels,
    SharedString, TitlebarOptions, WindowBounds, WindowOptions,
};
use nativeapi::geometry::{Point, Rectangle};
use nativeapi::window::Window as NativeWindow;
use nativeapi::window_drag_session::{WindowDragEvent, WindowDragSession};
use nativeapi::window_manager::WindowManager;

use crate::layout::{TabLayout, DETACH_MARGIN, TAB_TOP};
use crate::native::{contains, content_offset, native_window_of, to_screen};
use crate::page::TabPage;
use crate::views::BrowserWindowView;

pub type TabId = usize;
pub type WindowKey = usize;

/// Content size of the windows that open at startup.
pub const DEFAULT_WINDOW_SIZE: (f64, f64) = (760.0, 520.0);
const MIN_WINDOW_SIZE: (f32, f32) = (420.0, 280.0);
/// How far the cursor has to travel from the press before a tab moves.
const POP_OUT_DISTANCE: f64 = 8.0;

/// Tab dot colours (Material indigo, teal, deep orange, pink, green, purple,
/// blue grey, amber).
const PALETTE: [u32; 8] = [
    0x3f51b5, 0x009688, 0xff5722, 0xe91e63, 0x4caf50, 0x9c27b0, 0x607d8b, 0xffc107,
];

/// One tab. Its page is a GPUI entity rendered by whichever window shows the
/// tab, so it keeps its state wherever the tab ends up.
pub struct BrowserTab {
    pub title: SharedString,
    pub color: u32,
    pub page: Entity<TabPage>,
}

/// A browser window: a tab strip and the pages of its tabs.
pub struct BrowserWindow {
    pub key: WindowKey,
    handle: Option<AnyWindowHandle>,
    native: Option<NativeWindow>,
    pub tabs: Vec<TabId>,
    pub active: Option<TabId>,
    /// The strip's bounds in the window's content coordinates, written by the
    /// view every time it lays out.
    pub strip: Rc<Cell<Option<Bounds<Pixels>>>>,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
enum Mode {
    /// Pressed on a tab, not moved far enough yet.
    Pending,
    /// The tab moves along the strip of [`Drag::window`].
    InStrip,
    /// [`Drag::window`] holds only the dragged tab and follows the cursor.
    Window,
    /// The window itself is being moved by its strip background.
    MoveWindow,
}

#[derive(Clone, Copy, Debug)]
struct Drag {
    tab: Option<TabId>,
    window: WindowKey,
    /// Where the tab was grabbed, relative to its top-left corner.
    grab: gpui::Point<f64>,
    /// Screen position of the press.
    press: gpui::Point<f64>,
    mode: Mode,
    /// Left edge of the dragged tab relative to the strip, while `InStrip`.
    left: f64,
}

/// A tab leaving its strip mid-drag: the window to open for it.
pub struct TearOff {
    tab: TabId,
    source: WindowKey,
    /// Screen rectangle for the new window's content.
    content: Rectangle,
}

pub struct Tabs {
    pub layout: TabLayout,
    tabs: HashMap<TabId, BrowserTab>,
    windows: Vec<BrowserWindow>,
    session: Option<WindowDragSession>,
    drag: Option<Drag>,
    next_tab: TabId,
    next_window: WindowKey,
}

impl Tabs {
    pub fn new(cx: &mut Context<Self>) -> Self {
        // nativeapi calls the listener synchronously from the platform event
        // loop; hop onto a GPUI task so the handler gets a context.
        let session = if cfg!(any(target_os = "macos", target_os = "windows")) {
            WindowDragSession::new()
        } else {
            None
        };
        if let Some(session) = &session {
            let (tx, mut rx) = mpsc::unbounded::<WindowDragEvent>();
            session.add_listener(move |event| {
                let _ = tx.unbounded_send(event.clone());
            });
            cx.spawn(async move |this, cx| {
                while let Some(event) = rx.next().await {
                    let Ok(tear_off) = this.update(cx, |tabs, cx| tabs.on_drag(event, cx)) else {
                        break;
                    };
                    let Some(tear_off) = tear_off else {
                        continue;
                    };
                    let Some(this) = this.upgrade() else {
                        break;
                    };
                    // Outside the update above: opening a window draws it
                    // once, and drawing reads this entity.
                    let _ = cx.update(|cx| {
                        let opened =
                            open_browser_window(&this, vec![tear_off.tab], &tear_off.content, cx);
                        this.update(cx, |tabs, cx| tabs.follow_torn_off(&tear_off, opened, cx));
                    });
                }
            })
            .detach();
        }

        Self {
            layout: TabLayout::platform(),
            tabs: HashMap::new(),
            windows: Vec::new(),
            session,
            drag: None,
            next_tab: 1,
            next_window: 1,
        }
    }

    // -----------------------------------------------------------------------
    // Tabs and windows
    // -----------------------------------------------------------------------

    pub fn create_tab(&mut self, cx: &mut Context<Self>) -> TabId {
        let id = self.next_tab;
        self.next_tab += 1;
        let title: SharedString = format!("Tab {id}").into();
        let color = PALETTE[(id - 1) % PALETTE.len()];
        let page = cx.new(|cx| TabPage::new(id, title.clone(), color, cx));
        self.tabs.insert(id, BrowserTab { title, color, page });
        id
    }

    pub fn tab(&self, id: TabId) -> Option<&BrowserTab> {
        self.tabs.get(&id)
    }

    pub fn window(&self, key: WindowKey) -> Option<&BrowserWindow> {
        self.windows.iter().find(|window| window.key == key)
    }

    fn window_mut(&mut self, key: WindowKey) -> Option<&mut BrowserWindow> {
        self.windows.iter_mut().find(|window| window.key == key)
    }

    fn native(&self, key: WindowKey) -> Option<&NativeWindow> {
        self.window(key)?.native.as_ref()
    }

    pub fn can_drag(&self) -> bool {
        self.session.is_some()
    }

    fn register_window(&mut self, tabs: Vec<TabId>) -> WindowKey {
        let key = self.next_window;
        self.next_window += 1;
        self.windows.push(BrowserWindow {
            key,
            handle: None,
            native: None,
            active: tabs.first().copied(),
            tabs,
            strip: Rc::default(),
        });
        key
    }

    pub fn add_tab(&mut self, key: WindowKey, cx: &mut Context<Self>) {
        let tab = self.create_tab(cx);
        if let Some(window) = self.window_mut(key) {
            window.tabs.push(tab);
            window.active = Some(tab);
        }
        cx.notify();
    }

    pub fn activate(&mut self, key: WindowKey, tab: TabId, cx: &mut Context<Self>) {
        if let Some(window) = self.window_mut(key) {
            if window.active != Some(tab) {
                window.active = Some(tab);
                cx.notify();
            }
        }
    }

    pub fn close_tab(&mut self, key: WindowKey, tab: TabId, cx: &mut Context<Self>) {
        if self.drag.is_some_and(|drag| drag.tab == Some(tab)) {
            return;
        }
        self.remove_tab(key, tab);
        self.tabs.remove(&tab);
        if self
            .window(key)
            .is_some_and(|window| window.tabs.is_empty())
        {
            self.close_window(key, cx);
        } else {
            cx.notify();
        }
    }

    pub fn close_window(&mut self, key: WindowKey, cx: &mut Context<Self>) {
        let Some(index) = self.windows.iter().position(|window| window.key == key) else {
            return;
        };
        let window = self.windows.remove(index);
        if self.drag.is_some_and(|drag| drag.window == key) {
            self.drag = None;
            if let Some(session) = &self.session {
                session.cancel();
            }
        }
        for tab in &window.tabs {
            self.tabs.remove(tab);
        }
        if let Some(native) = &window.native {
            native.hide();
        }
        drop(window.native);
        let handle = window.handle;
        let last = self.windows.is_empty();
        // Removed after the current update: the caller may be running inside
        // that very window.
        cx.defer(move |cx| {
            if let Some(handle) = handle {
                let _ = handle.update(cx, |_, window, _| window.remove_window());
            }
            if last {
                cx.quit();
            }
        });
        cx.notify();
    }

    fn remove_tab(&mut self, key: WindowKey, tab: TabId) {
        let Some(window) = self.window_mut(key) else {
            return;
        };
        let Some(index) = window.tabs.iter().position(|&t| t == tab) else {
            return;
        };
        window.tabs.remove(index);
        if window.active == Some(tab) {
            window.active = window
                .tabs
                .get(index.min(window.tabs.len().saturating_sub(1)))
                .copied();
        }
    }

    // -----------------------------------------------------------------------
    // Queries for the strip
    // -----------------------------------------------------------------------

    /// Left edge of `tab` while it is being dragged along `key`'s strip, or
    /// `None` if it sits in its slot.
    pub fn dragged_left(&self, key: WindowKey, tab: TabId) -> Option<f64> {
        let drag = self.drag?;
        (drag.tab == Some(tab) && drag.window == key && drag.mode == Mode::InStrip)
            .then_some(drag.left)
    }

    pub fn is_dragging(&self, tab: TabId) -> bool {
        self.drag.is_some_and(|drag| drag.tab == Some(tab))
    }

    // -----------------------------------------------------------------------
    // Starting drags
    // -----------------------------------------------------------------------

    /// The mouse went down on `tab`. `grab` is relative to the tab,
    /// `position` to the window's content.
    pub fn press_tab(
        &mut self,
        key: WindowKey,
        tab: TabId,
        grab: gpui::Point<f64>,
        position: gpui::Point<Pixels>,
        cx: &mut Context<Self>,
    ) {
        self.activate(key, tab, cx);
        let (Some(session), Some(native)) = (&self.session, self.native(key)) else {
            return;
        };
        if self.drag.is_some() {
            return;
        }
        // Follow the pointer without moving anything until it travels far enough.
        if !session.start(None, &Point { x: 0.0, y: 0.0 }) {
            return;
        }
        let content = native.content_bounds();
        self.drag = Some(Drag {
            tab: Some(tab),
            window: key,
            grab,
            press: point(
                content.x + f64::from(position.x),
                content.y + f64::from(position.y),
            ),
            mode: Mode::Pending,
            left: 0.0,
        });
    }

    /// The mouse went down on the strip background: move the window.
    pub fn press_strip(&mut self, key: WindowKey, position: gpui::Point<Pixels>) {
        let (Some(session), Some(native)) = (&self.session, self.native(key)) else {
            return;
        };
        if self.drag.is_some() {
            return;
        }
        let inset = content_offset(native);
        let anchor = Point {
            x: inset.x + f64::from(position.x),
            y: inset.y + f64::from(position.y),
        };
        if session.start(Some(native), &anchor) {
            self.drag = Some(Drag {
                tab: None,
                window: key,
                grab: point(0.0, 0.0),
                press: point(0.0, 0.0),
                mode: Mode::MoveWindow,
                left: 0.0,
            });
        }
    }

    // -----------------------------------------------------------------------
    // The drag state machine
    // -----------------------------------------------------------------------

    fn on_drag(&mut self, event: WindowDragEvent, cx: &mut Context<Self>) -> Option<TearOff> {
        let mut drag = self.drag?;
        match event {
            WindowDragEvent::Moved {
                cursor_position, ..
            } => self.on_move(&mut drag, point(cursor_position.x, cursor_position.y), cx),
            WindowDragEvent::Ended { .. } => {
                self.drag = None;
                if drag.mode == Mode::Window {
                    // The press went to another window, which the release
                    // brings back to the front; the dragged window stays on top.
                    if let Some(native) = self.native(drag.window) {
                        native.focus();
                    }
                }
                cx.notify();
                None
            }
            WindowDragEvent::Cancelled { .. } => {
                self.drag = None;
                cx.notify();
                None
            }
        }
    }

    fn on_move(
        &mut self,
        drag: &mut Drag,
        cursor: gpui::Point<f64>,
        cx: &mut Context<Self>,
    ) -> Option<TearOff> {
        match drag.mode {
            Mode::MoveWindow => None,
            Mode::Pending => {
                let distance = (cursor.x - drag.press.x).hypot(cursor.y - drag.press.y);
                if distance < POP_OUT_DISTANCE {
                    return None;
                }
                drag.mode = Mode::InStrip;
                self.move_in_strip(drag, cursor, cx)
            }
            Mode::InStrip => self.move_in_strip(drag, cursor, cx),
            Mode::Window => {
                if let Some(target) = self.window_with_strip_at(cursor, drag.window) {
                    self.merge_into(drag, target, cursor, cx);
                }
                None
            }
        }
    }

    fn move_in_strip(
        &mut self,
        drag: &mut Drag,
        cursor: gpui::Point<f64>,
        cx: &mut Context<Self>,
    ) -> Option<TearOff> {
        let strip = self.strip_rect(drag.window)?;
        if cursor.y < strip.y - DETACH_MARGIN || cursor.y > strip.y + strip.height + DETACH_MARGIN {
            return self.tear_off(drag, cursor, cx);
        }
        self.place_in_strip(drag, &strip, cursor);
        self.drag = Some(*drag);
        cx.notify();
        None
    }

    /// Positions the dragged tab under the cursor in `drag.window`'s strip and
    /// moves it to the index it now covers.
    fn place_in_strip(&mut self, drag: &mut Drag, strip: &Rectangle, cursor: gpui::Point<f64>) {
        let layout = self.layout;
        let (Some(tab), Some(window)) = (drag.tab, self.window_mut(drag.window)) else {
            return;
        };
        let count = window.tabs.len();
        let extent = layout.tab_extent(strip.width, count);
        drag.left = layout.clamp_left(cursor.x - strip.x - drag.grab.x, extent, count);
        let index = layout.index_for_left(drag.left, extent, count);
        if let Some(current) = window.tabs.iter().position(|&t| t == tab) {
            if index != current {
                window.tabs.remove(current);
                window.tabs.insert(index, tab);
            }
        }
    }

    fn tear_off(
        &mut self,
        drag: &mut Drag,
        cursor: gpui::Point<f64>,
        cx: &mut Context<Self>,
    ) -> Option<TearOff> {
        let source = drag.window;
        let tab = drag.tab?;
        let (count, native) = {
            let window = self.window(source)?;
            (window.tabs.len(), window.native.as_ref()?)
        };

        if count == 1 {
            // Nothing would be left behind: carry the whole window instead.
            let anchor = self.anchor_for(native, drag);
            let session = self.session.as_ref()?;
            session.start(Some(native), &anchor);
            drag.mode = Mode::Window;
            self.drag = Some(*drag);
            cx.notify();
            return None;
        }

        // The new window's content is as large as the source's, placed so
        // that the grabbed point of its first tab is under the cursor.
        let size = native.content_size();
        let content = Rectangle {
            x: cursor.x - self.layout.leading_inset - drag.grab.x,
            y: cursor.y - TAB_TOP - drag.grab.y,
            width: size.width,
            height: size.height,
        };
        self.remove_tab(source, tab);
        self.drag = Some(*drag);
        cx.notify();
        Some(TearOff {
            tab,
            source,
            content,
        })
    }

    /// Hands the running drag over to a torn-off tab's freshly opened window.
    fn follow_torn_off(
        &mut self,
        tear_off: &TearOff,
        opened: Option<WindowKey>,
        cx: &mut Context<Self>,
    ) {
        cx.notify();
        let Some(mut drag) = self.drag else {
            return;
        };
        let Some(key) = opened else {
            // No window to put it in: back into its strip.
            if let Some(window) = self.window_mut(tear_off.source) {
                window.tabs.push(tear_off.tab);
                window.active = Some(tear_off.tab);
            }
            return;
        };
        let (Some(session), Some(native)) = (&self.session, self.native(key)) else {
            self.drag = None;
            return;
        };
        let anchor = self.anchor_for(native, &drag);
        // Released while the window was being created: it stays where it is.
        if !session.is_active() || !session.start(Some(native), &anchor) {
            self.drag = None;
            session.cancel();
            return;
        }
        native.focus();
        drag.window = key;
        drag.mode = Mode::Window;
        self.drag = Some(drag);
    }

    /// The frame point that keeps the grabbed point of a window's first tab
    /// under the cursor.
    fn anchor_for(&self, native: &NativeWindow, drag: &Drag) -> Point {
        let inset = content_offset(native);
        Point {
            x: inset.x + self.layout.leading_inset + drag.grab.x,
            y: inset.y + TAB_TOP + drag.grab.y,
        }
    }

    fn merge_into(
        &mut self,
        drag: &mut Drag,
        target: WindowKey,
        cursor: gpui::Point<f64>,
        cx: &mut Context<Self>,
    ) {
        let (Some(strip), Some(tab)) = (self.strip_rect(target), drag.tab) else {
            return;
        };
        let dragged = drag.window;

        // Stop moving the dragged window before it goes away; the gesture goes
        // on as a drag along the target's strip.
        if let Some(session) = &self.session {
            session.start(None, &Point { x: 0.0, y: 0.0 });
        }
        drag.window = target;
        drag.mode = Mode::InStrip;
        self.drag = Some(*drag);
        self.remove_tab(dragged, tab);
        self.close_window(dragged, cx);

        if let Some(window) = self.window_mut(target) {
            window.tabs.push(tab);
            window.active = Some(tab);
        }
        self.place_in_strip(drag, &strip, cursor);
        self.drag = Some(*drag);
        if let Some(native) = self.native(target) {
            native.focus();
        }
        cx.notify();
    }

    // -----------------------------------------------------------------------
    // Hit testing
    // -----------------------------------------------------------------------

    /// The window whose tab strip is under `cursor` and not covered by another
    /// window, looking through `excluding`.
    fn window_with_strip_at(
        &self,
        cursor: gpui::Point<f64>,
        excluding: WindowKey,
    ) -> Option<WindowKey> {
        let excluded_id = self.native(excluding).map_or(0, |native| native.id());
        let point = Point {
            x: cursor.x,
            y: cursor.y,
        };
        let hit = WindowManager::get_window_at_point(&point, excluded_id)?.id();
        let window = self.windows.iter().find(|window| {
            window.key != excluding && window.native.as_ref().map(|n| n.id()) == Some(hit)
        })?;
        let strip = self.strip_rect(window.key)?;
        contains(&strip, &point).then_some(window.key)
    }

    /// A window's tab strip in screen coordinates.
    fn strip_rect(&self, key: WindowKey) -> Option<Rectangle> {
        let window = self.window(key)?;
        Some(to_screen(window.native.as_ref()?, window.strip.get()?))
    }
}

/// Opens a browser window showing `tabs`, with its content covering
/// `content` on screen. Must not run inside an update of `this`: opening a
/// window draws it once, and drawing reads `this`.
pub fn open_browser_window(
    this: &Entity<Tabs>,
    tabs: Vec<TabId>,
    content: &Rectangle,
    cx: &mut App,
) -> Option<WindowKey> {
    let key = this.update(cx, |this, _| this.register_window(tabs));
    let options = WindowOptions {
        window_bounds: Some(WindowBounds::Windowed(Bounds::new(
            point(px(content.x as f32), px(content.y as f32)),
            size(px(content.width as f32), px(content.height as f32)),
        ))),
        // The strip replaces the title bar: on macOS the traffic lights stay,
        // centred in the strip; on Windows the strip has its own close button.
        titlebar: Some(TitlebarOptions {
            title: Some("Browser".into()),
            appears_transparent: true,
            traffic_light_position: Some(point(px(12.), px(13.))),
        }),
        // The strip moves windows itself (through the drag session); the
        // system must not move them for drags in the title bar band.
        is_movable: false,
        window_min_size: Some(size(px(MIN_WINDOW_SIZE.0), px(MIN_WINDOW_SIZE.1))),
        ..Default::default()
    };
    let mut native = None;
    let opened = cx.open_window(options, |window, cx| {
        native = native_window_of(window);
        let tabs = this.clone();
        window.on_window_should_close(cx, move |_, cx| {
            tabs.update(cx, |tabs, cx| tabs.close_window(key, cx));
            false
        });
        cx.new(|cx| BrowserWindowView::new(this.clone(), key, cx))
    });
    let Ok(handle) = opened else {
        this.update(cx, |this, _| {
            this.windows.retain(|window| window.key != key)
        });
        return None;
    };
    // GPUI places the window frame; put the content exactly over `content`.
    if let Some(native) = &native {
        native.set_content_bounds(content);
    }
    this.update(cx, |this, cx| {
        if let Some(window) = this.window_mut(key) {
            window.handle = Some(handle.into());
            window.native = native;
        }
        cx.notify();
    });
    Some(key)
}
