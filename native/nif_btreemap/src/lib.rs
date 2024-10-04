use rustler::{Env, Binary, Encoder, NifResult, ResourceArc, Term};

use std::collections::BTreeMap;
use std::sync::Mutex;
use std::str;
use std::time::Instant;

rustler::atoms! {
    ok,
    error,
    invalid_input_size
}

struct SortedMapResource {
    map: Mutex<BTreeMap<String, String>>,
}

fn load(env: Env, _load_info: Term) -> bool {
    _ = rustler::resource!(SortedMapResource, env);
    true
}

#[rustler::nif]
fn new() -> NifResult<ResourceArc<SortedMapResource>> {
    let resource = ResourceArc::new(SortedMapResource {
        map: Mutex::new(BTreeMap::new()),
    });

    Ok(resource)
}

#[rustler::nif]
fn insert<'a>(
    env: Env<'a>,
    resource: ResourceArc<SortedMapResource>,
    key: Binary<'a>,
    val: Binary<'a>,
) -> NifResult<Term<'a>> {
    let mut map = resource.map.lock().unwrap();
    let key_str = str::from_utf8(&key).unwrap().to_string();
    let val_str = str::from_utf8(&val).unwrap().to_string();

    _ = map.insert(key_str, val_str);

    Ok(ok().encode(env))
}

#[rustler::nif]
fn get<'a>(
    env: Env<'a>,
    resource: ResourceArc<SortedMapResource>,
    key: Binary<'a>,
) -> NifResult<Term<'a>> {
    let map = resource.map.lock().unwrap();
    let key_str = str::from_utf8(&key).unwrap().to_string();

    match map.get(&key_str) {
        Some(val) => {
            Ok((ok(), val).encode(env))
        }
        None => {
            Ok(error().encode(env))
        }
    }
}

#[rustler::nif]
fn prev<'a>(
    env: Env<'a>,
    resource: ResourceArc<SortedMapResource>,
    key: Binary<'a>,
) -> NifResult<Term<'a>> {
    let map = resource.map.lock().unwrap();
    let key_str = str::from_utf8(&key).unwrap().to_string();

    match map.range(..key_str).next_back() {
        Some((k, v)) => {
            Ok((k, v).encode(env))
        }
        None => {
            Ok(error().encode(env))
        }
    }
}

#[rustler::nif]
fn prev<'a>(
    env: Env<'a>,
    resource: ResourceArc<SortedMapResource>,
    key: Binary<'a>,
    count: i64,
) -> NifResult<Term<'a>> {
    let start = Instant::now();
    let map = resource.map.lock().unwrap();
    let key_str = str::from_utf8(&key).unwrap().to_string();
    let take_iter = map.range(..key_str).rev().take(count as usize);
    let vec : Vec<(&String, &String)> = take_iter.collect();

    println!("prev_count: {:?}", start.elapsed());

    Ok(vec.encode(env))
}

rustler::init!("Elixir.RustSortedMap", load = load);