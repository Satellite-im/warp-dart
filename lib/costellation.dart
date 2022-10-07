import 'dart:async';
import 'dart:convert';
import 'dart:ffi';
import 'dart:io';
import 'dart:isolate';
import 'dart:math';
import 'dart:typed_data';
import 'package:ffi/ffi.dart';
//import 'package:flutter/foundation.dart';
import 'package:warp_dart/warp.dart';
import 'package:warp_dart/warp_dart_bindings_generated.dart';
import 'package:warp_dart/fs_memory.dart';

enum ConstellationDataType { json, yaml, toml }

class Item {
  late Pointer<G_Item> _pointer;
  Item(this._pointer);

  String getItemId() {
    String id;
    Pointer<Char> pointerId = bindings.item_id(_pointer);
    if (pointerId == nullptr) {
      throw Exception("Directory not found");
    }
    id = pointerId.cast<Utf8>().toDartString();
    calloc.free(pointerId);
    return id;
  }

  String getItemName() {
    Pointer<Char> pointerName = bindings.item_name(_pointer);

    if (pointerName == nullptr) {
      throw Exception("Item not found");
    }
    String name = pointerName.cast<Utf8>().toDartString();
    calloc.free(pointerName);
    return name;
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
    bool result = bindings.item_set_description(
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

  Directory itemToDirectory() {
    G_FFIResult_Directory result = bindings.item_into_directory(_pointer);
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
    bool result = bindings.item_is_directory(_pointer);

    if (result == 0) {
      return false;
    }

    return true;
  }

  bool itemIsFile() {
    bool result = bindings.item_is_file(_pointer);

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
  late String id;
  late String name;
  late int size;
  late String description;
  late DateTime creation;
  late DateTime modified;
  late String hash;
  late String? reference;
  late Pointer<G_File> _pointer;

  File(this._pointer) {
    Pointer<G_Item> item = bindings.file_into_item(_pointer);
    Pointer<Char> pId = bindings.item_id(item);
    id = pId.cast<Utf8>().toDartString();
    Pointer<Char> pName = bindings.item_name(item);
    name = pName.cast<Utf8>().toDartString();
    size = bindings.item_size(item);
    Pointer<Char> pDescription = bindings.item_description(item);
    description = pDescription.cast<Utf8>().toDartString();
    Pointer<Char> pCreation = bindings.item_creation(item);
    String creationString = pCreation.cast<Utf8>().toDartString();
    creation =
        DateTime.parse(creationString.substring(0, creationString.length - 4));
    Pointer<Char> pModified = bindings.item_modified(item);
    String modifiedString = pModified.cast<Utf8>().toDartString();
    modified =
        DateTime.parse(modifiedString.substring(0, modifiedString.length - 4));
    hash = item.hashCode.toString();

    calloc.free(pId);
    calloc.free(pName);
    calloc.free(pDescription);
    calloc.free(pCreation);
    calloc.free(pModified);
    bindings.item_free(item);
  }

  File.newFile(String name) {
    _pointer = bindings.file_new(name.toNativeUtf8().cast<Char>());
  }

  File getOwnFile() {
    return File(_pointer);
  }

  void setDescription(String descritpion) {
    Pointer<G_Item> item = bindings.file_into_item(_pointer);

    if (item == nullptr) {
      throw Exception("File not found");
    }

    bindings.item_set_description(
        item, descritpion.toNativeUtf8().cast<Char>());

    _pointer = bindings.item_into_file(item).data;
  }

  void rename(String name) {
    Pointer<G_Item> item = bindings.file_into_item(_pointer);

    if (item == nullptr) {
      throw Exception("File not found");
    }

    bindings.item_rename(item, name.toNativeUtf8().cast<Char>());

    _pointer = bindings.item_into_file(item).data;
  }

  void drop() {
    bindings.file_free(_pointer);
  }
}

class Directory {
  late Pointer<G_Directory> _pointer;
  late String id;
  late String name;
  late String description;
  late DateTime creation;
  late DateTime modified;

  Directory(this._pointer) {
    Pointer<Char> pId = bindings.directory_id(_pointer);
    id = pId.cast<Utf8>().toDartString();
    Pointer<Char> pName = bindings.directory_name(_pointer);
    name = pName.cast<Utf8>().toDartString();
    Pointer<Char> pDescription = bindings.directory_description(_pointer);
    description = pDescription.cast<Utf8>().toDartString();
    int pCreation = bindings.directory_creation(_pointer);
    creation = DateTime.fromMillisecondsSinceEpoch(pCreation);
    int pModified = bindings.directory_modified(_pointer);
    modified = DateTime.fromMillisecondsSinceEpoch(pModified);

    calloc.free(pId);
    calloc.free(pName);
    calloc.free(pDescription);
  }

  Directory.newDirectory(String name) {
    _pointer = bindings.directory_new(name.toNativeUtf8().cast<Char>());
  }

  Directory getDirectory() {
    return Directory(_pointer);
  }

  void addDirectory(Directory directory) {
    G_FFIResult_Null result =
        bindings.directory_add_directory(_pointer, directory.pointer());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  bool hasItem(Directory directory) {
    Pointer<Char> item = directory.name.toNativeUtf8().cast<Char>();

    bool has_item = bindings.directory_has_item(_pointer, item);

    if (has_item == 0) {
      return false;
    }
    calloc.free(item);
    return true;
  }

  void addFile(File file) {
    G_FFIResult_Null result =
        bindings.directory_add_file(_pointer, file._pointer);

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

  Item directoryToItem() {
    Pointer<G_Item> result = bindings.directory_into_item(_pointer);

    if (result == nullptr) {
      throw Exception("File not found");
    }
    Item item = Item(result);
    bindings.item_free(result);
    return item;
  }

  void setDescription(String descritpion) {
    Pointer<G_Item> item = bindings.directory_into_item(_pointer);

    if (item == nullptr) {
      throw Exception("File not found");
    }

    bindings.item_set_description(
        item, descritpion.toNativeUtf8().cast<Char>());

    _pointer = bindings.item_into_directory(item).data;
  }

  void rename(String name) {
    Pointer<G_Item> item = bindings.directory_into_item(_pointer);

    if (item == nullptr) {
      throw Exception("File not found");
    }

    bindings.item_rename(item, name.toNativeUtf8().cast<Char>());

    _pointer = bindings.item_into_directory(item).data;
  }

  Item getItem(String itemS) {
    G_FFIResult_Item result = bindings.directory_get_item(
        _pointer, itemS.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    Item item = Item(result.data);

    bindings.item_free(result.data);
    return item;
  }

  int getItemIndex(String item) {
    G_FFIResult_usize result = bindings.directory_get_item_index(
        _pointer, item.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    int index = result.data.value;
    calloc.free(result.data);
    return index;
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
    bool result = bindings.directory_move_item_to(_pointer,
        src.toNativeUtf8().cast<Char>(), dst.toNativeUtf8().cast<Char>());

    if (!result) {
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
    bindings.item_free(result.data);
  }

  void removeItemFromPath(String directory, String item) {
    G_FFIResult_Item result = bindings.directory_remove_item_from_path(
        _pointer,
        directory.toNativeUtf8().cast<Char>(),
        item.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
    bindings.item_free(result.data);
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
        _pointer, path.toNativeUtf8().cast<Char>(), false);
    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  Constellation.createRecursiveDirectoryInFilesystem(String path) {
    G_FFIResult_Null result = bindings.constellation_create_directory(
        _pointer, path.toNativeUtf8().cast<Char>(), true);

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
    Directory dir = Directory(pointerDirectory);
    return dir;
  }

  Directory getCurrentDirectoryMutable() {
    Pointer<G_Directory> pointerDirectory =
        bindings.constellation_current_directory_mut(_pointer);

    if (pointerDirectory == nullptr) {
      throw Exception("Directory not found");
    }
    bindings.directory_free(pointerDirectory);
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

  Uint8List downloadFileFromFilesystemIntoBuffer(String remotePath) {
    List<int> buffer = [];
    G_FFIResult_FFIVec_u8 result = bindings.constellation_get_buffer(
        _pointer, remotePath.toNativeUtf8().cast<Char>());

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }

    int length = result.data.ref.len;

    for (int i = 0; i < length; i++) {
      int pointer = result.data.ref.ptr.elementAt(i).value;
      buffer.add(pointer);
    }

    Uint8List list = Uint8List.fromList(buffer);
    calloc.free(result.data);
    return list;
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
    Directory dir = Directory(result.data);
    return dir;
  }

  void uploadToFilesystem(String remotePath, String localPath) {
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
    Directory dir = Directory(pointerDirectory);

    return dir;
  }

  void removeItem(String remotePath, bool recursive) {
    G_FFIResult_Null result = bindings.constellation_remove(
        _pointer, remotePath.toNativeUtf8().cast<Char>(), recursive);

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

  void uploadToFilesystemFromBuffer(String remotePath, Uint8List buffer) {
    Pointer<Uint8> bufferP = malloc.allocate(buffer.length);
    bufferP[0] = buffer[0];
    G_FFIResult_Null result = bindings.constellation_put_buffer(_pointer,
        remotePath.toNativeUtf8().cast<Char>(), bufferP, buffer.length);

    if (result.error != nullptr) {
      throw WarpException(result.error);
    }
  }

  void drop() {
    bindings.constellationadapter_free(_pointer);
  }
}
