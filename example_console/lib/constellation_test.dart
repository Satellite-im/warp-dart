import 'dart:io';
import 'package:warp_dart/costellation.dart';
import 'package:warp_dart/fs_memory.dart';
import 'package:warp_dart/warp.dart';
import 'package:example_console/common.dart';

void test_fs_memory() {
  try {
    print("==== Test for fs_memory ====");

    print("\nCreate Filesystem\n");
    Constellation constellation = initConstellation();

    print("\nCreate Diretory\n");
    Directory directory = constellation.newDirectory("warp-dart-directory-1");

    print("\nCreate Diretory on filesystem\n");
    constellation.createDirectoryInFilesystem("warp-dart-directory-fs-1");

    print("\nGet directory details\n");
    print("Directory Id: ${directory.id}");
    print("Directory Name: ${directory.name}");

    /*print("\nAdd description to Directory\n");
    directory.setDescription("This is my directory");

    print("\nGet directory details\n");
    print("Directory Id: ${directory.id}");
    print("Directory Name: ${directory.name}");
    print("Directory Description: ${directory.description}");*/

    print("\nUpload file to filesystem...");
    String remote = "test.txt";
    String local = "./filesystem";
    try {
      constellation.UploadToFilesystem(remote, "$local/in/test.txt");
      print("File uploaded to /$remote");
    } on WarpException catch (e) {
      print(e.errorMessage());
    }

    print("\nDownload file from filesystem...");
    try {
      constellation.downloadFileFromFilesystem(remote, "$local/out/test.txt");
      print("File dowloaded to $local/out/test.txt");
    } on WarpException catch (e) {
      print(e.errorMessage());
    }

    print("\nDownload file into buffer\n");
    List<int> buffer;
    try {
      buffer = constellation.downloadFileFromFilesystemIntoBuffer(remote);
      sleep(Duration(seconds: 1));
      print(buffer);
    } on WarpException catch (e) {
      print(e.errorMessage());
    }

    print("\nSelect Directory from filesystem\n");
    try {
      constellation.selectItem("warp-dart-directory-fs-1");
      print("Directory founded");
    } on WarpException catch (e) {
      print(e.errorMessage());
    }

    print("\nOpen Directory from filesystem\n");
    try {
      constellation.openDirectory("warp-dart-directory-fs-1");
      print("Directory opened");
    } on WarpException catch (e) {
      print(e.errorMessage());
    }

    print("\nGet current Directory from filesystem\n");
    try {
      Directory currDir = constellation.getCurrentDirectory();
      print("Current Directory: ${currDir.name}");
    } on WarpException catch (e) {
      print(e.errorMessage());
    }

    print("\nGet root Directory from filesystem\n");
    try {
      Directory rootDir = constellation.getRootDirectory();
      print("Root Directory: ${rootDir.name}");
    } on WarpException catch (e) {
      print(e.errorMessage());
    }

    print("\nGet Constellation filesystem structure in json format\n");
    try {
      print(
          "Json:\n ${constellation.exportConstellationInOtherTypes(ConstellationDataType.json)}");
    } on WarpException catch (e) {
      print(e.errorMessage());
    }

    print("\nGet Constellation filesystem structure in toml format\n");
    try {
      print(
          "Toml:\n ${constellation.exportConstellationInOtherTypes(ConstellationDataType.toml)}");
    } on WarpException catch (e) {
      print(e.errorMessage());
    }

    print("\nGet Constellation filesystem structure in yaml format\n");
    try {
      print(
          "Yaml:\n ${constellation.exportConstellationInOtherTypes(ConstellationDataType.yaml)}");
    } on WarpException catch (e) {
      print(e.errorMessage());
    }

    print("\nChange directory description\n");
    try {
      directory = directory.rename("warp-dart-directory-fs-2");
      print("Directory name: ${directory.name}");
    } on WarpException catch (e) {
      print(e.errorMessage());
    }

    print("\nChange directory description\n");
    try {
      directory = directory.setDescription("my first directory");
      print("Directory name: ${directory.name}");
      print("Directory description: ${directory.description}");
    } on WarpException catch (e) {
      print(e.errorMessage());
    }

    print("\nNew file\n");
    File file = constellation.newFile("File");
    try {
      print("File name: ${file.name}");
      print("File description: ${file.description}");
    } on WarpException catch (e) {
      print(e.errorMessage());
    }

    print("\nChange file description\n");
    try {
      file = file.rename("File 2");
      print("File name: ${file.name}");
    } on WarpException catch (e) {
      print(e.errorMessage());
    }

    print("\nChange directory description\n");
    try {
      file = file.setDescription("my first file");
      print("File name: ${file.name}");
      print("File description: ${file.description}");
    } on WarpException catch (e) {
      print(e.errorMessage());
    }
  } on WarpException catch (e) {
    print(e.errorMessage());
  }
}
