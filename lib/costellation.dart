import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
import 'package:flutter/foundation.dart';
import 'package:warp_dart/warp.dart';
import 'package:warp_dart/warp_dart_bindings_generated.dart';
import 'package:warp_dart/fs_memory.dart';

enum ConstellationDataType { json, yaml, toml }

class Item {
  late Pointer<G_Item> _pointer;
  Item(this._pointer);

  String getItemId(Item item) {
    Pointer<Char> pointerId;
    String id;
    pointerId = bindings.item_id(item.pointer());
    if (pointerId == nullptr) {
      throw Exception("Directory not found");
    }
    id = pointerId.cast<Utf8>().toDartString();

    return id;
  }

  String getItemName(Item item) {
    Pointer<Char> pointerName = bindings.item_name(item.pointer());

    if (pointerName == nullptr) {
      throw Exception("Item not found");
    }
    return pointerName.cast<Utf8>().toDartString();
  }

  String getItemTimestamp() {
    Pointer<Char> timestamp = bindings.item_creation(_pointer);

    if (timestamp == nullptr) {
      throw Exception("Item not found");
    }

    var date = timestamp.cast<Utf8>().toDartString();
    return date;
  }

  String getItemDateModification() {
    Pointer<Char> timestamp = bindings.item_modified(_pointer);

    if (timestamp == nullptr) {
      throw Exception("Item not found");
    }

    var date = timestamp.cast<Utf8>().toDartString();
    return date;
  }

  String getItemDescription() {
    Pointer<Char> pointerDescription = bindings.item_description(_pointer);

    String description = pointerDescription.cast<Utf8>().toDartString();

    return description;
  }

  int getItemSize() {
    int size = bindings.item_size(_pointer);

    return size;
  }

  void ItemRename(String name) {
    G_FFIResult_Null result =
        bindings.item_rename(_pointer, name.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void setItemDescription(String description) {
    int result = bindings.item_set_description(
        _pointer, description.toNativeUtf8().cast<Char>());

    if (result == 0) {
      throw Exception("Setting of item is failed");
    }
  }

  void setItemSize(int size) {
    G_FFIResult_Null result = bindings.item_set_size(_pointer, size);

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  Directory itemToDirectory(Item item) {
    G_FFIResult_Directory result = bindings.item_into_directory(item.pointer());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    Directory directory = Directory(result.data);

    return directory;
  }

  File itemToFile(Item item) {
    G_FFIResult_File result = bindings.item_into_file(item.pointer());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    File file = File(result.data);

    return file;
  }

  bool itemIsDirectory() {
    int result = bindings.item_is_directory(_pointer);

    if (result == 0) {
      return false;
    }

    return true;
  }

  bool itemIsFile() {
    int result = bindings.item_is_file(_pointer);

    if (result == 0) {
      return false;
    }

    return true;
  }

  Pointer<G_Item> pointer() {
    return _pointer;
  }

  void drop() {
    bindings.item_free(_pointer);
  }
}

class File {
  late Pointer<G_File> _pointer;
  File(this._pointer);

  File.newFile(String name) {
    _pointer = bindings.file_new(name.toNativeUtf8().cast<Char>());
  }

  Item fileToItem(File file) {
    Pointer<G_Item> result = bindings.file_into_item(file.pointer());

    if (result == nullptr) {
      throw Exception("File not found");
    }

    return Item(result);
  }

  Pointer<G_File> pointer() {
    return _pointer;
  }

  void drop() {
    bindings.file_free(_pointer);
  }
}

class Directory {
  late Pointer<G_Directory> _pointer;
  Directory(this._pointer);

  Directory.newDirectory(String name) {
    _pointer = bindings.directory_new(name.toNativeUtf8().cast<Char>());
  }

  String getDirectoryId(Directory directory) {
    Pointer<Char> pointerId;
    String id;
    pointerId = bindings.directory_id(directory.pointer());
    if (pointerId == nullptr) {
      throw Exception("Directory not found");
    }
    id = bindings.directory_id(directory.pointer()).cast<Utf8>().toDartString();

    return id;
  }

  void addDirectory(Directory directory) {
    G_FFIResult_Null result =
        bindings.directory_add_directory(_pointer, directory.pointer());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  String getDirectoryName(Directory directory) {
    return bindings
        .directory_name(directory.pointer())
        .cast<Utf8>()
        .toDartString();
  }

  String getDirectoryTimestamp() {
    int timestamp = bindings.directory_creation(_pointer);

    var date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

    return date.toString();
  }

  String getDirectoryDateModification() {
    int timestamp = bindings.directory_modified(_pointer);

    var date = DateTime.fromMillisecondsSinceEpoch(timestamp * 1000);

    return date.toString();
  }

  String getDirectoryDescription() {
    Pointer<Char> pointerDescription = bindings.directory_description(_pointer);

    String description = pointerDescription.cast<Utf8>().toDartString();

    return description;
  }

  bool hasItem(Directory directory) {
    Pointer<Char> item =
        getDirectoryName(directory).toNativeUtf8().cast<Char>();

    int has_item = bindings.directory_has_item(_pointer, item);

    if (has_item == 0) {
      return false;
    }
    return true;
  }

  void addFile(File file) {
    G_FFIResult_Null result =
        bindings.directory_add_file(_pointer, file.pointer());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void addItem(Item item) {
    G_FFIResult_Null result =
        bindings.directory_add_item(_pointer, item.pointer());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  Item directoryToItem(Directory directory) {
    Pointer<G_Item> result = bindings.directory_into_item(directory.pointer());

    if (result == nullptr) {
      throw Exception("File not found");
    }
    return Item(result);
  }

  Item getItem(String item) {
    G_FFIResult_Item result =
        bindings.directory_get_item(_pointer, item.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }

    return Item(result.data);
  }

  int getItemIndex(String item) {
    G_FFIResult_usize result = bindings.directory_get_item_index(
        _pointer, item.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }

    return result.data.cast<Uint64>().value;
  }

  List<Item> listItems() {
    Pointer<G_FFIVec_Item> pointerListItem =
        bindings.directory_get_items(_pointer);
    if (pointerListItem == nullptr) {
      throw Exception("Items or directory not found");
    }
    List<Item> list = [];
    int length = pointerListItem.ref.len;

    for (int i = 0; i < length; i++) {
      Pointer<G_Item> pointer = pointerListItem.ref.ptr.elementAt(i).value;
      Item key = Item(pointer);
      list.add(key);
    }
    return list;
  }

  void moveItemTo(String src, String dst) {
    int result = bindings.directory_move_item_to(_pointer,
        src.toNativeUtf8().cast<Char>(), dst.toNativeUtf8().cast<Char>());

    if (result == 0) {
      throw Exception("Item not found or path is wrong");
    }
  }

  int getDirectorySize() {
    int size = bindings.directory_size(_pointer);

    return size;
  }

  void renameItem(String currentName, String newName) {
    G_FFIResult_Null result = bindings.directory_rename_item(
        _pointer,
        currentName.toNativeUtf8().cast<Char>(),
        newName.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void removeItem(String name) {
    G_FFIResult_Item result = bindings.directory_remove_item(
        _pointer, name.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void removeItemFromPath(String directory, String item) {
    G_FFIResult_Item result = bindings.directory_remove_item_from_path(
        _pointer,
        directory.toNativeUtf8().cast<Char>(),
        item.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  Pointer<G_Directory> pointer() {
    return _pointer;
  }

  void drop() {
    bindings.directory_free(_pointer);
  }
}

class Constellation {
  late Pointer<G_ConstellationAdapter> _pointer;
  Constellation(this._pointer);

  void createDirectoryInFilesystem(String path) {
    G_FFIResult_Null result = bindings.constellation_create_directory(
        _pointer, path.toNativeUtf8().cast<Char>(), 0);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  Constellation.createRecursiveDirectoryInFilesystem(String path) {
    G_FFIResult_Null result = bindings.constellation_create_directory(
        _pointer, path.toNativeUtf8().cast<Char>(), 1);

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  Directory getCurrentDirectory() {
    Pointer<G_Directory> pointerDirectory =
        bindings.constellation_current_directory(_pointer);

    if (pointerDirectory == nullptr) {
      throw Exception("Directory not found");
    }
    return Directory(pointerDirectory);
  }

  Directory getCurrentDirectoryMutable() {
    Pointer<G_Directory> pointerDirectory =
        bindings.constellation_current_directory_mut(_pointer);

    if (pointerDirectory == nullptr) {
      throw Exception("Directory not found");
    }

    return Directory(pointerDirectory);
  }

  String exportConstellationInOtherTypes(ConstellationDataType type) {
    G_FFIResult_String result =
        bindings.constellation_export(_pointer, type.index);

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }

    String data = result.data.cast<Utf8>().toDartString();

    calloc.free(result.data);
    return data;
  }

  void downloadFileFromFilesystem(String remotePath, String localPath) {
    G_FFIResult_Null result = bindings.constellation_get(
        _pointer,
        remotePath.toNativeUtf8().cast<Char>(),
        localPath.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  List<int> downloadFileFromFilesystemIntoBuffer(String remotePath) {
    List<int> buffer = [];
    G_FFIResult_FFIVec_u8 result = bindings.constellation_get_buffer(
        _pointer, remotePath.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }

    int length = result.data.ref.len;

    for (int i = 0; i < length; i++) {
      int pointer = result.data.ref.ptr.elementAt(i).value;
      int key = pointer;
      buffer.add(key);
    }

    return buffer;
  }

  void previousDirectory() {
    G_FFIResult_Null result = bindings.constellation_go_back(_pointer);

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void importDataToFilesystem(ConstellationDataType dataType, String data) {
    G_FFIResult_Null result = bindings.constellation_import(
        _pointer, dataType.index, data.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void moveItem(String src, String dst) {
    G_FFIResult_Null result = bindings.constellation_move_item(_pointer,
        src.toNativeUtf8().cast<Char>(), dst.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  Directory openDirectory(String name) {
    G_FFIResult_Directory result = bindings.constellation_open_directory(
        _pointer, name.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    return Directory(result.data);
  }

  void UploadToFilesystem(String remotePath, String localPath) {
    G_FFIResult_Null result = bindings.constellation_put(
        _pointer,
        remotePath.toNativeUtf8().cast<Char>(),
        localPath.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  Directory getRootDirectory() {
    Pointer<G_Directory> pointerDirectory =
        bindings.constellation_root_directory(_pointer);

    if (pointerDirectory == nullptr) {
      throw Exception("Directory not found");
    }

    return Directory(pointerDirectory);
  }

  void removeItem(String remotePath, bool recursive) {
    int intRecursive = 0;

    if (recursive == true) {
      intRecursive = 1;
    }

    G_FFIResult_Null result = bindings.constellation_remove(
        _pointer, remotePath.toNativeUtf8().cast<Char>(), intRecursive);

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void selectItem(String name) {
    G_FFIResult_Null result = bindings.constellation_select(
        _pointer, name.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void syncReference(String src) {
    G_FFIResult_Null result = bindings.constellation_sync_ref(
        _pointer, src.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  /*void UploadToFilesystemFromBuffer(String remotePath, List<Uint8> buffer) {
    G_FFIResult_Null result = bindings.constellation_put_buffer(_pointer,
        remotePath.toNativeUtf8().cast<Char>(), , buffer.length);

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }*/

  void drop() {
    bindings.constellationadapter_free(_pointer);
  }
}
