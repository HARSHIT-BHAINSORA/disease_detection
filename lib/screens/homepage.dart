import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final ImagePicker _picker = ImagePicker();
  XFile? _image;
  String? _diseaseName;
  String? _precaution;

  Future<void> _pickImage(ImageSource source) async {
    final XFile? image = await _picker.pickImage(source: source);
    setState(() {
      _image = image;
      _diseaseName = null; // Reset disease name when a new image is picked
      _precaution = null; // Reset precaution when a new image is picked
    });
  }

  Future<void> _detectDisease() async {
    if (_image == null) return;

    final request = http.MultipartRequest(
      'POST',
      Uri.parse('http://192.168.110.107:5000/predict'),
    );
    request.files.add(await http.MultipartFile.fromPath(
      'image',
      _image!.path,
    ));

    final response = await request.send();

    if (response.statusCode == 200) {
      final responseData = await response.stream.bytesToString();
      final result = jsonDecode(responseData);
      print(result);
      setState(() {
        _diseaseName = result[
            'disease']; // Assuming the server returns a JSON with a 'disease' key
        _precaution = result[
            'precaution']; // Assuming the server returns a JSON with a 'precaution' key
      });
    } else {
      setState(() {
        _diseaseName = 'Error detecting disease';
        _precaution = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Plant"),
        leading: _image == null && _diseaseName == null && _precaution == null
            ? null
            : IconButton(
                icon: Icon(Icons.arrow_back),
                onPressed: () {
                  setState(() {
                    _image = null;
                    _diseaseName = null;
                    _precaution = null;
                  });
                },
              ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Container(
              width: double.infinity,
              height: 300,
              color: const Color.fromARGB(255, 3, 5, 3),
              child: _image == null
                  ? Center(
                      child: Text(
                        'Upload Image',
                        style: TextStyle(color: Colors.white, fontSize: 20),
                      ),
                    )
                  : Image.file(
                      File(_image!.path),
                      fit: BoxFit.cover,
                    ),
            ),
            SizedBox(height: 20),
            _image != null
                ? _diseaseName != null
                    ? Column(
                        children: [
                          SizedBox(height: 20),
                          Text(
                            _diseaseName!,
                            style: TextStyle(
                                fontSize: 20, fontWeight: FontWeight.bold),
                          ),
                          SizedBox(height: 10),
                          Text(
                            _precaution ?? '',
                            style: TextStyle(fontSize: 16),
                          ),
                          SizedBox(height: 20),
                          ElevatedButton(
                            onPressed: () {
                              setState(() {
                                _image = null;
                                _diseaseName = null;
                                _precaution = null;
                              });
                            },
                            child: Text('Back'),
                            style: ElevatedButton.styleFrom(
                              foregroundColor: Colors.white,
                              backgroundColor: Colors.black,
                            ),
                          )
                        ],
                      )
                    : Column(
                        children: [
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _detectDisease,
                              child: Text('Detect Disease'),
                              style: ElevatedButton.styleFrom(
                                foregroundColor: Colors.white,
                                backgroundColor: Colors.black,
                              ),
                            ),
                          )
                        ],
                      )
                : Column(
                    children: [
                      SizedBox(
                        width: 300,
                        child: ElevatedButton(
                          onPressed: () => _pickImage(ImageSource.gallery),
                          child: Text('Image from Gallery'),
                          style: ElevatedButton.styleFrom(
                            side: BorderSide(width: 80),
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 10),
                      SizedBox(
                        width: 300,
                        child: ElevatedButton(
                          onPressed: () => _pickImage(ImageSource.camera),
                          child: Text('Camera'),
                          style: ElevatedButton.styleFrom(
                            foregroundColor: Colors.white,
                            backgroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(5.0),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ],
        ),
      ),
    );
  }
}
