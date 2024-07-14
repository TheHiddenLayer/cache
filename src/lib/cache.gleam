
// these are some changes

import gleam/dict.{type Dict}
import gleam/erlang/process.{type Subject}
import gleam/otp/actor

// Type alias for a Gleam dict
type TinyCacheDataStore(v) =
  Dict(String, v)

// Subject for TinyCache Messages
pub type TinyCacheSubject(v) =
  Subject(Message(v))

/// Messages which the TinyCache actor understands
///   Keys -> send client all keys
///   Get -> send client value for key
///   Set -> insert <key, value> pair
///   Shutdown -> stop actor process normally
pub type Message(v) {
  Keys(reply_with: Subject(List(String)))
  Get(reply_with: Subject(Result(v, Nil)), key: String)
  Set(key: String, value: v)
  Shutdown
}

/// Loop function for actor
fn handle_message(
  message: Message(v),
  store: TinyCacheDataStore(v),
) -> actor.Next(Message(v), TinyCacheDataStore(v)) {
  case message {
    Keys(client) -> {
      process.send(client, dict.keys(store))
      actor.continue(store)
    }
    Get(client, key) -> {
      process.send(client, dict.get(store, key))
      actor.continue(store)
    }
    Set(key, value) -> {
      let store = dict.insert(store, key, value)
      actor.continue(store)
    }
    Shutdown -> actor.Stop(process.Normal)
  }
}

/// Start TinyCache
pub fn new() -> Result(TinyCacheSubject(v), actor.StartError) {
  actor.start(dict.new(), handle_message)
}

/// Retrieve all keys
pub fn keys(tiny_cache: TinyCacheSubject(v)) -> List(String) {
  actor.call(tiny_cache, Keys, 1000)
}

 //these are more changes
/// Get value for key
pub fn get(tiny_cache: TinyCacheSubject(v), key: String) -> Result(v, Nil) {
  actor.call(tiny_cache, Get(_, key), 1000)
}

/// Set <key:value> pair
pub fn set(tiny_cache: TinyCacheSubject(v), key: String, value: v) {
  process.send(tiny_cache, Set(key, value))
}
