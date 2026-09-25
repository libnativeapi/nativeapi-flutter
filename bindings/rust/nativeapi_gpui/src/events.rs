use std::rc::Rc;

use futures::channel::mpsc;
use futures::StreamExt;
use gpui::{Context, Task};
use nativeapi::window::WindowEvent;
use nativeapi::window_drag_session::{WindowDragEvent, WindowDragSession};
use nativeapi::window_manager::WindowManager;

/// Keeps a nativeapi listener registered and its events flowing into GPUI.
/// Dropping it removes the listener; [`detach`](Self::detach) keeps it for the
/// rest of the app's life.
#[must_use = "dropping the subscription removes the listener"]
pub struct NativeSubscription {
    task: Option<Task<()>>,
    unsubscribe: Option<Box<dyn FnOnce()>>,
}

impl NativeSubscription {
    pub fn detach(mut self) {
        if let Some(task) = self.task.take() {
            task.detach();
        }
        self.unsubscribe = None;
    }
}

impl Drop for NativeSubscription {
    fn drop(&mut self) {
        if let Some(unsubscribe) = self.unsubscribe.take() {
            unsubscribe();
        }
    }
}

/// Delivers every [`WindowEvent`] (of every window) to the entity `cx`
/// belongs to, like GPUI's `cx.observe`.
///
/// nativeapi calls its listeners synchronously from the platform event loop,
/// with no GPUI context and possibly while GPUI is in the middle of an update;
/// the events are queued and handed to `f` from a GPUI task instead, where it
/// may open windows and make native calls. The subscription ends when the
/// entity is released. Works while the entity is being constructed.
pub fn observe_window_events<T: 'static>(
    cx: &mut Context<T>,
    f: impl FnMut(&mut T, WindowEvent, &mut Context<T>) + 'static,
) -> NativeSubscription {
    let (tx, rx) = mpsc::unbounded();
    let listener = WindowManager::add_listener(move |event| {
        let _ = tx.unbounded_send(event.clone());
    });
    NativeSubscription {
        task: Some(forward(rx, f, cx)),
        unsubscribe: Some(Box::new(move || {
            WindowManager::remove_listener(listener);
        })),
    }
}

/// Delivers the events of a [`WindowDragSession`] to the entity `cx` belongs
/// to, like [`observe_window_events`].
///
/// `f` runs inside an update of that entity: to open a window whose view
/// reads the entity (GPUI draws a new window once before `open_window`
/// returns), `cx.defer` the opening.
pub fn observe_drag_session<T: 'static>(
    session: &Rc<WindowDragSession>,
    cx: &mut Context<T>,
    f: impl FnMut(&mut T, WindowDragEvent, &mut Context<T>) + 'static,
) -> NativeSubscription {
    let (tx, rx) = mpsc::unbounded();
    let listener = session.add_listener(move |event| {
        let _ = tx.unbounded_send(event.clone());
    });
    let session = session.clone();
    NativeSubscription {
        task: Some(forward(rx, f, cx)),
        unsubscribe: Some(Box::new(move || {
            session.remove_listener(listener);
        })),
    }
}

fn forward<T: 'static, E: 'static>(
    mut rx: mpsc::UnboundedReceiver<E>,
    mut f: impl FnMut(&mut T, E, &mut Context<T>) + 'static,
    cx: &mut Context<T>,
) -> Task<()> {
    cx.spawn(async move |entity, cx| {
        while let Some(event) = rx.next().await {
            if entity.update(cx, |this, cx| f(this, event, cx)).is_err() {
                break;
            }
        }
    })
}
