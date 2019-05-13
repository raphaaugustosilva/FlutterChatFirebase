import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:image_picker/image_picker.dart';

class PaginaPrincipal extends StatefulWidget {
  @override
  _PaginaPrincipalState createState() => _PaginaPrincipalState();
}

final ThemeData kiOSTheme = ThemeData(
  primarySwatch: Colors.orange,
  primaryColor: Colors.grey[100],
  primaryColorBrightness: Brightness.light,
);

final ThemeData kDefaultTheme = ThemeData(
  primarySwatch: Colors.purple,
  accentColor: Colors.orangeAccent[400],
);

final auth = FirebaseAuth.instance;
final autenticadorGoogle = GoogleSignIn();

Future<Null> _garanteQueUsuarioEstaLogado() async {
  GoogleSignInAccount usuarioGoogle = autenticadorGoogle.currentUser;
  //Tenta fazer o login de forma silenciosa
  if (usuarioGoogle == null)
    usuarioGoogle = await autenticadorGoogle.signInSilently();

  //Se ainda assim estiver nulo, então pede para fazer o login
  if (usuarioGoogle == null) usuarioGoogle = await autenticadorGoogle.signIn();

  //Verifica agora se o usuário do FIREBASE é nulo
  if (await auth.currentUser() == null) {
    GoogleSignInAuthentication credenciaisGoogle =
        await autenticadorGoogle.currentUser.authentication;

    await auth.signInWithGoogle(
        idToken: credenciaisGoogle.idToken,
        accessToken: credenciaisGoogle.accessToken);
  }
}

_trataEnvioMensagem(String texto) async {
  await _garanteQueUsuarioEstaLogado();
  _enviarMensagem(texto: texto);
}

void _enviarMensagem({String texto, String urlImagem}) {
  Firestore.instance.collection("mensagens").add({
    "texto": texto,
    "urlImagem": urlImagem,
    "nomeRemetente": autenticadorGoogle.currentUser.displayName,
    "urlImagemRemetente": autenticadorGoogle.currentUser.photoUrl,
  });
}

class _PaginaPrincipalState extends State<PaginaPrincipal> {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: "Aplicativo de Chat",
      debugShowCheckedModeBanner: false,
      theme: Theme.of(context).platform == TargetPlatform.iOS
          ? kiOSTheme
          : kDefaultTheme,
      home: SafeArea(
        bottom: false,
        top: false,
        child: Scaffold(
            appBar: AppBar(
              title: Text("Aplicativo de Chat"),
              centerTitle: true,
              elevation:
                  Theme.of(context).platform == TargetPlatform.iOS ? 0 : 4,
            ),
            body: Column(
              children: <Widget>[
                Expanded(
                    child: StreamBuilder(
                  stream:
                      Firestore.instance.collection("mensagens").snapshots(),
                  builder: (context, snapshot) {
                    switch (snapshot.connectionState) {
                      case ConnectionState.none:
                      case ConnectionState.waiting:
                        return Center(
                          child: CircularProgressIndicator(),
                        );

                      default:
                        return ListView.builder(
                          reverse: true,
                          itemCount: snapshot.data.documents.length,
                          itemBuilder: (context, index) {
                            List listaInvertida =
                                snapshot.data.documents.reversed.toList();
                            return BlocoMensagensChat(
                                listaInvertida[index].data);
                          },
                        );
                    }
                  },
                )),
                Divider(height: 1),
                Container(
                  decoration: BoxDecoration(
                    color: Theme.of(context).cardColor,
                  ),
                  child: CriaBlocoEnviarMensagem(),
                ),
              ],
            )
            //,
            ),
      ),
    );
  }
}

class BlocoMensagensChat extends StatelessWidget {
  final Map<String, dynamic> dados;

  BlocoMensagensChat(this.dados);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Container(
            margin: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              backgroundImage: NetworkImage(dados["urlImagemRemetente"]),
            ),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  dados["nomeRemetente"],
                  style: Theme.of(context).textTheme.subhead,
                ),
                Container(
                  margin: const EdgeInsets.only(top: 5),
                  child: dados["urlImagem"] != null
                      ? Image.network(
                          dados["urlImagem"],
                          width: 250,
                        )
                      : Text(dados["texto"]),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }
}

class CriaBlocoEnviarMensagem extends StatefulWidget {
  @override
  _CriaBlocoEnviarMensagemState createState() =>
      _CriaBlocoEnviarMensagemState();
}

class _CriaBlocoEnviarMensagemState extends State<CriaBlocoEnviarMensagem> {
  final _controladorMensagemASerEnviada = TextEditingController();
  bool _estaEscreventoTexto = false;

  void _resetar() {
    _controladorMensagemASerEnviada.clear();
    setState(() {
      _estaEscreventoTexto = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return IconTheme(
      data: IconThemeData(
        color: Theme.of(context).accentColor,
      ),
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8),
        decoration: Theme.of(context).platform == TargetPlatform.iOS
            ? BoxDecoration(
                border: Border(top: BorderSide(color: Colors.grey[200])),
              )
            : null,
        child: Row(
          children: <Widget>[
            Container(
              child: IconButton(
                icon: Icon(Icons.photo_camera),
                onPressed: () async {
                  await _garanteQueUsuarioEstaLogado();
                  File arquivoImagem =
                      await ImagePicker.pickImage(source: ImageSource.camera);
                  if (arquivoImagem == null) return;
                  StorageUploadTask taskEnvioArquivoStorageFirebase = FirebaseStorage.instance.ref().child(autenticadorGoogle.currentUser.id.toString() + DateTime.now().millisecondsSinceEpoch.toString()).putFile(arquivoImagem);
                  
                  StorageTaskSnapshot retornoTaskEnvioArquivoStorageFirebase = await taskEnvioArquivoStorageFirebase.onComplete;
                  String urlImagemArmazenadaStorageFirebase = await retornoTaskEnvioArquivoStorageFirebase.ref.getDownloadURL();

                  _enviarMensagem(urlImagem: urlImagemArmazenadaStorageFirebase);
                },
              ),
            ),
            Expanded(
              child: TextField(
                controller: _controladorMensagemASerEnviada,
                decoration:
                    InputDecoration.collapsed(hintText: "Enviar uma mensagem"),
                onChanged: (texto) {
                  setState(() {
                    _estaEscreventoTexto = texto.length > 0;
                  });
                },
                onSubmitted: (texto) {
                  _trataEnvioMensagem(texto);
                  _resetar();
                },
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Theme.of(context).platform == TargetPlatform.iOS
                  ? CupertinoButton(
                      child: Text("Enviar"),
                      onPressed: _estaEscreventoTexto
                          ? () {
                              _trataEnvioMensagem(
                                  _controladorMensagemASerEnviada.text);
                              _resetar();
                            }
                          : null)
                  : IconButton(
                      icon: Icon(Icons.send),
                      onPressed: _estaEscreventoTexto
                          ? () {
                              _trataEnvioMensagem(
                                  _controladorMensagemASerEnviada.text);
                              _resetar();
                            }
                          : null,
                    ),
            ),
          ],
        ),
      ),
    );
  }
}
