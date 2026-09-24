use anyhow::Result;

use crate::ir::model::Api;

/// Serialize an `Api` IR to a pretty-printed JSON string.
pub fn to_json_string(api: &Api) -> Result<String> {
    Ok(serde_json::to_string_pretty(api)?)
}

/// Deserialize an `Api` IR from a JSON string.
pub fn from_json_string(json: &str) -> Result<Api> {
    Ok(serde_json::from_str(json)?)
}
