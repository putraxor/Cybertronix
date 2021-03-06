import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart' as url_launcher;
import 'package:share/share.dart' as share;
import 'package:meta/meta.dart';
import 'package:image_picker/image_picker.dart';
import 'package:zoomable_image/zoomable_image.dart';
import '../../firebase.dart' as firebase;

/// A Material Card with a contact's info
/// 
/// Usually used with [showDialog]
class ContactInfoCard extends StatefulWidget {
  /// The contact's ID in Firebase
  final String contactID;
  /// The contact data stored in Firebase
  final Map<String, dynamic> contactData;

  /// A Material Card with a contact's info
  ContactInfoCard(this.contactID, {
    @required this.contactData
    });
  
  @override
  _ContactInfoCardState createState() => new _ContactInfoCardState();
}

class _ContactInfoCardState extends State<ContactInfoCard> {

  List<Widget> cardLines = <Widget>[];
  Map<String, dynamic> contactData;

  void goEdit(BuildContext context){
    Navigator.of(context).pushNamed('/create/contacts/${widget.contactID}').then((dynamic x){
      if (x is Map){
        setState((){
          contactData = x;
          populateLines();
        });
      }
    });
  }

  Future<Null> goPhotos() async {
    // Future: Display local copy instead of waiting for upload.
    File imageFile = await ImagePicker.pickImage();
    firebase.uploadPhoto(imageFile).then((String url){
      setState((){
        Map<String, dynamic> newData = new Map<String, dynamic>.from(contactData);
        if (newData["photos"] != null){
          newData["photos"].add(url);
        } else {
          newData["photos"] = <String>[url];
        }
        firebase.sendObject("contacts", newData, objID: widget.contactID);
        contactData = newData;
        populateLines();
      });
    });
  }

  void goShare(){ // Hook this into something!
    String shareString = "${contactData['name']}";
    if (contactData["phoneNumbers"] != null){
      contactData["phoneNumbers"].forEach((Map<String, String> phone){
        shareString += "\n${phone["type"]}: ${phone["number"]}";
      });
    }
    if (contactData["email"] != null){
      shareString += "\n${contactData['email']}";
    }
    share.share(shareString);
  }

  void populateLines(){
    cardLines.clear();
    cardLines.add(
      new Container( // Future: Make this a sliver
        height: 200.0,
        child: new Stack(
          children: <Widget>[
            new Positioned.fill(
              child: (){
                if (contactData["photos"] != null){
                  return new GestureDetector(
                    child: new Image.network(contactData["photos"].last, fit: BoxFit.fitWidth),
                    onTap: () async {
                      await showDialog(
                        context: context,
                        child: new ZoomableImage(
                          new NetworkImage(contactData["photos"].last),
                          scale: 10.0,
                          onTap: (){
                            Navigator.pop(context);
                          },
                        ),
                      );
                    },
                  );
                } else {
                  return new GestureDetector(
                    child: new Image.asset('assets/hey_ladies.jpg', fit: BoxFit.fitWidth),
                    onTap: goPhotos,
                  );
                }
              }(),
            ),
            new Positioned(
              left: 8.0,
              bottom: 16.0,
              child: new Text(
                contactData["name"],
                style: new TextStyle(
                  color: Colors.white,
                  fontSize: 24.0,
                  fontWeight: FontWeight.bold
                )
              )
            ),
            new Positioned(
              right: 8.0,
              top: 8.0,
              child: new IconButton(
                icon: new Icon(Icons.share, color: Colors.white),
                iconSize: 36.0,
                onPressed: goShare,
              ),
            )
          ]
        )
      )
    );
    if (contactData["company"] != null){
      cardLines.add(
        new ListTile(
          leading: new Icon(Icons.business),
          title: new Text(contactData["company"])
        )
      );
    }
    cardLines.add(new Divider());
    if (contactData["phoneNumbers"] != null) {
      contactData["phoneNumbers"].forEach((Map<String, String> phone){
        cardLines.add(
          new ListTile(
            leading: (){
              if (phone["type"] == "Cell"){
                return new Icon(Icons.phone_android);
              } else if (phone["type"] == "Office") {
                return new Icon(Icons.work);
              } else {
                return null;
              }
            }(),
            title: new Text(phone["number"]),
            trailing: new Row(
              children: <Widget>[
                new IconButton(
                  icon: new Icon(Icons.message),
                  onPressed: (){
                    url_launcher.launch('sms:${phone["number"]}');
                  },
                ),
                new IconButton(
                  icon: new Icon(Icons.phone),
                  onPressed: (){
                    url_launcher.launch('tel:${phone["number"]}');
                  },
                ),
              ],
            ),
          ),
        );
      });
    }
    if (contactData["email"] != null) {
      cardLines.add(
        new ListTile(
          title: new Text(contactData["email"]),
          trailing: new Row(
            children: <Widget>[
              new IconButton(
                icon: new Icon(Icons.mail),
                onPressed: (){url_launcher.launch("mailto:${contactData['email']}");}
              )
            ]
          )
        )
      );
    }
  }

  @override
  void initState() {
    super.initState();
    contactData = widget.contactData;
    populateLines();
  }

  @override
  Widget build(BuildContext context){
    return new Container(
      padding: const EdgeInsets.fromLTRB(8.0, 28.0, 8.0, 12.0),
      child: new Card(
        child: new Column(
          children: new List<Widget>.from(cardLines)
        )
      )
    );
  }
}