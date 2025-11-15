use jni::objects::{JClass, JObject, JString, JByteArray, JValueGen};
use jni::sys::{jboolean, jint, jlong, jbyteArray, jintArray};
use jni::JNIEnv;
use std::sync::{Arc, RwLock};

mod store;
mod snapshot;

use store::{RAMStore, StoreStats};

static STORE: once_cell::sync::Lazy<Arc<RwLock<Option<RAMStore>>>> = 
    once_cell::sync::Lazy::new(|| Arc::new(RwLock::new(None)));

#[no_mangle]
pub extern "system" fn Java_com_hydra_jni_RAMStoreJNI_initialize(
    mut env: JNIEnv,
    _class: JClass,
    max_size_bytes: jlong,
    snapshot_path: JString,
) {
    let snapshot_path_str: String = env
        .get_string(&snapshot_path)
        .expect("Couldn't get snapshot path")
        .into();
    
    let store = RAMStore::new(max_size_bytes as usize, snapshot_path_str);
    *STORE.write().unwrap() = Some(store);
}

#[no_mangle]
pub extern "system" fn Java_com_hydra_jni_RAMStoreJNI_put(
    mut env: JNIEnv,
    _class: JClass,
    job_id: JString,
    chunk_index: jint,
    data: JByteArray,
    checksum: JByteArray,
    ttl_seconds: jlong,
) -> jboolean {
    let job_id_str: String = env
        .get_string(&job_id)
        .expect("Couldn't get job ID")
        .into();
    
    let data_len = env.get_array_length(&data).unwrap() as usize;
    let mut data_bytes = vec![0i8; data_len];
    env.get_byte_array_region(&data, 0, &mut data_bytes).unwrap();
    let data_bytes_u8: Vec<u8> = data_bytes.iter().map(|&b| b as u8).collect();
    
    let checksum_len = env.get_array_length(&checksum).unwrap() as usize;
    let mut checksum_bytes = vec![0i8; checksum_len];
    env.get_byte_array_region(&checksum, 0, &mut checksum_bytes).unwrap();
    let checksum_bytes_u8: Vec<u8> = checksum_bytes.iter().map(|&b| b as u8).collect();
    
    let store = STORE.read().unwrap();
    if let Some(ref s) = *store {
        let checksum_array: [u8; 32] = checksum_bytes_u8.try_into().unwrap_or_else(|_| [0u8; 32]);
        let result = s.put(
            &job_id_str,
            chunk_index as u32,
            data_bytes_u8,
            checksum_array,
            ttl_seconds,
        );
        if result { 1 } else { 0 }
    } else {
        0
    }
}

#[no_mangle]
pub extern "system" fn Java_com_hydra_jni_RAMStoreJNI_get(
    mut env: JNIEnv,
    _class: JClass,
    job_id: JString,
    chunk_index: jint,
) -> jbyteArray {
    let job_id_str: String = env
        .get_string(&job_id)
        .expect("Couldn't get job ID")
        .into();
    
    let store = STORE.read().unwrap();
    if let Some(ref s) = *store {
        if let Some(data) = s.get(&job_id_str, chunk_index as u32) {
            let array = env.new_byte_array(data.len() as i32).unwrap();
            let data_i8: Vec<i8> = data.iter().map(|&b| b as i8).collect();
            env.set_byte_array_region(&array, 0, &data_i8).unwrap();
            return array.into_raw();
        }
    }
    
    env.new_byte_array(0).unwrap().into_raw()
}

#[no_mangle]
pub extern "system" fn Java_com_hydra_jni_RAMStoreJNI_getChunkIndices(
    mut env: JNIEnv,
    _class: JClass,
    job_id: JString,
) -> jintArray {
    let job_id_str: String = env
        .get_string(&job_id)
        .expect("Couldn't get job ID")
        .into();
    
    let store = STORE.read().unwrap();
    if let Some(ref s) = *store {
        let indices = s.get_chunk_indices(&job_id_str);
        let array = env.new_int_array(indices.len() as i32).unwrap();
        let indices_i32: Vec<i32> = indices.iter().map(|&x| x as i32).collect();
        env.set_int_array_region(&array, 0, &indices_i32).unwrap();
        return array.into_raw();
    }
    
    env.new_int_array(0).unwrap().into_raw()
}

#[no_mangle]
pub extern "system" fn Java_com_hydra_jni_RAMStoreJNI_delete(
    mut env: JNIEnv,
    _class: JClass,
    job_id: JString,
    chunk_index: jint,
) -> jboolean {
    let job_id_str: String = env
        .get_string(&job_id)
        .expect("Couldn't get job ID")
        .into();
    
    let mut store = STORE.write().unwrap();
    if let Some(ref mut s) = *store {
        if s.delete(&job_id_str, chunk_index as u32) { 1 } else { 0 }
    } else {
        0
    }
}

#[no_mangle]
pub extern "system" fn Java_com_hydra_jni_RAMStoreJNI_deleteJob(
    mut env: JNIEnv,
    _class: JClass,
    job_id: JString,
) -> jboolean {
    let job_id_str: String = env
        .get_string(&job_id)
        .expect("Couldn't get job ID")
        .into();
    
    let mut store = STORE.write().unwrap();
    if let Some(ref mut s) = *store {
        if s.delete_job(&job_id_str) { 1 } else { 0 }
    } else {
        0
    }
}

#[no_mangle]
pub extern "system" fn Java_com_hydra_jni_RAMStoreJNI_snapshot(
    _env: JNIEnv,
    _class: JClass,
) {
    let store = STORE.read().unwrap();
    if let Some(ref s) = *store {
        s.snapshot();
    }
}

#[no_mangle]
pub extern "system" fn Java_com_hydra_jni_RAMStoreJNI_restore(
    _env: JNIEnv,
    _class: JClass,
) {
    let mut store = STORE.write().unwrap();
    if let Some(ref mut s) = *store {
        s.restore();
    }
}

#[no_mangle]
pub extern "system" fn Java_com_hydra_jni_RAMStoreJNI_emergencyCheckpoint(
    _env: JNIEnv,
    _class: JClass,
) {
    let store = STORE.read().unwrap();
    if let Some(ref s) = *store {
        s.emergency_checkpoint();
    }
}

#[no_mangle]
pub extern "system" fn Java_com_hydra_jni_RAMStoreJNI_getStats<'a>(
    mut env: JNIEnv<'a>,
    _class: JClass<'a>,
) -> JObject<'a> {
    let store = STORE.read().unwrap();
    if let Some(ref s) = *store {
        let stats = s.get_stats();
        // Create Java StoreStats object
        let stats_class = env.find_class("com/hydra/ramstore/StoreStats").unwrap();
        let stats_obj = env.new_object(
            stats_class,
            "(JJID)V",
            &[
                JValueGen::Long(stats.current_size_bytes as i64),
                JValueGen::Long(stats.max_size_bytes as i64),
                JValueGen::Int(stats.chunk_count as i32),
                JValueGen::Double(stats.hit_rate),
            ],
        ).unwrap();
        return stats_obj;
    }
    
    let stats_class = env.find_class("com/hydra/ramstore/StoreStats").unwrap();
    env.new_object(
        stats_class,
        "(JJID)V",
        &[
            JValueGen::Long(0i64),
            JValueGen::Long(0i64),
            JValueGen::Int(0i32),
            JValueGen::Double(0.0f64),
        ],
    ).unwrap()
}

