import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:firebase_storage/firebase_storage.dart';

Future<void> _handleLogout(BuildContext context) async {
  try {
    await FirebaseAuth.instance.signOut();
    // Il logout è stato completato con successo
    // Ora puoi navigare l'utente alla schermata di accesso o a una schermata iniziale.
    Navigator.pushReplacementNamed(context, '/login'); // Sostituisci con la tua schermata di login
  } catch (e) {
    // Gestisci eventuali errori durante il logout qui
    print("Errore durante il logout: $e");
  }
}

Future<String> getImageUrl(String uid) async {
  final Reference storageRef =
      FirebaseStorage.instance.ref('$uid/profilo/immagine_base.jpg');
  final String downloadURL = await storageRef.getDownloadURL();
  return downloadURL;
}

Future<String> getImageUrlSondaggio(String postid, String nomeImmagine) async {
  final Reference storageRef =
      FirebaseStorage.instance.ref('sondaggi/$postid/$nomeImmagine');
  final String downloadURL = await storageRef.getDownloadURL();
  return downloadURL;
}

Future<Map<String, dynamic>?> getUserData(String uid) async {
  try {
    // Ottieni un riferimento al documento dell'utente utilizzando l'UID
    DocumentSnapshot<Map<String, dynamic>> userDoc =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    // Verifica se il documento esiste
    if (userDoc.exists) {
      // Estrai i dati del documento
      Map<String, dynamic> userData = userDoc.data()!;
      return userData;
    } else {
      // Il documento non esiste, puoi gestire questa situazione come preferisci
      return null; // Oppure restituisci un messaggio di errore
    }
  } catch (e) {
    // Gestisci eventuali errori
    return null; // Oppure restituisci un messaggio di errore
  }
}

Future<List<Comment>> getComments() async {
  try {
    QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await FirebaseFirestore.instance.collection('sondaggi').get();

    List<Comment> comments = querySnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data();

      String imgString = data['img'];
      List<String> imgList = imgString.split(',');
      if (imgList.isNotEmpty) {
        imgList.removeAt(0);
      }

      return Comment(data['date'], data['desc'], data['time'], data['uid'],
          imgList, data['postId']);
    }).toList();

    return comments;
  } catch (e) {
    print('Errore durante il recupero dei commenti: $e');
    return [];
  }
}

Future<List<Consiglio>> getConsigli() async {
  try {
    QuerySnapshot<Map<String, dynamic>> querySnapshot =
        await FirebaseFirestore.instance.collection('consigli').get();

    List<Consiglio> consigli = querySnapshot.docs.map((doc) {
      Map<String, dynamic> data = doc.data();

      return Consiglio(
        data['dataCreazione'],
        data['dataEvento'],
        data['desc'],
        data['oraCreazione'],
        data['temaEvento'],
        data['uid'],
      );
    }).toList();

    return consigli;
  } catch (e) {
    print('Errore durante il recupero dei consigli: $e');
    return [];
  }
}

Future<String> getUsername(String uid) async {
  try {
    // Ottieni un riferimento al documento dell'utente utilizzando l'UID
    var userData =
        await FirebaseFirestore.instance.collection('users').doc(uid).get();
    // Verifica se il documento esiste
    if (userData.exists) {
      // Estrai i dati del documento
      String username = userData.data()?['username'] as String;
      return username;
    } else {
      // Il documento non esiste, puoi gestire questa situazione come preferisci
      return "null"; // Oppure restituisci un messaggio di errore
    }
  } catch (e) {
    // Gestisci eventuali errori
    return "null"; // Oppure restituisci un messaggio di errore
  }
}

Future<void> main() async {
  // Sostituisci con l'UID dell'utente che desideri ottenere

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(
      home: HomeActivity(),
    );
  }
}

class HomeActivity extends StatefulWidget {
  const HomeActivity({super.key});

  @override
  HomeActivityState createState() => HomeActivityState();
}

class Comment {
  final String dataCreazione;
  final String desc;
  final String oraCreazione;
  final String uid;
  final List<String> img;
  final String postId;

  Comment(this.dataCreazione, this.desc, this.oraCreazione, this.uid, this.img,
      this.postId);
}

class Consiglio {
  final String dataCreazione;
  final String dataEvento;
  final String desc;
  final String oraCreazione;
  final String temaEvento;
  final String uid;

  Consiglio(this.dataCreazione, this.dataEvento, this.desc, this.oraCreazione,
      this.temaEvento, this.uid);
}

class HomeActivityState extends State<HomeActivity> {
  Map<String, dynamic>? userData;
  String immagineProfiloUrl = "";
  int _currentIndex = 0; // Indice della pagina corrente
  late List<Consiglio> consiglio = [];
  late List<Comment> comments = [];
  List<String> scelte = ["Scelta 1", "Scelta 2", "Scelta 3"];

  String? selectedScelta;

  @override
  void initState() {
    super.initState();
    consiglio = [];
    comments = [];

    getComments().then((commentList) {
      setState(() {
        comments = commentList;
      });
    });

    // Esegui l'operazione asincrona per ottenere i dati qui
    User? user = FirebaseAuth.instance.currentUser;
    String uid =
        user!.uid; // Sostituisci con l'UID dell'utente che desideri ottenere

    getImageUrl(uid).then((value) {
      setState(() {
        immagineProfiloUrl = value;
      });
    });

    getUserData(uid).then((data) {
      setState(() {
        userData = data;
      });
    });

    getConsigli().then((consigliList) {
      setState(() {
        consiglio = consigliList;
      });
    });
  }

  // Lista delle pagine da visualizzare nella navigazione inferiore
  final List<Widget> _pages = [
    const Center(
        child: Text(
      'Consigli',
      style: TextStyle(fontSize: 24.0),
    )),
    const Center(
      child: Text(
        'Commenti',
        style: TextStyle(fontSize: 24.0),
      ),
    ),
    const Center(
      child: Text(
        'Ricerca',
        style: TextStyle(fontSize: 24.0),
      ),
    ),
    // Aggiungi altre pagine qui
  ];

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: Future.delayed(const Duration(seconds: 2)),
      // Ritardo di 2 secondi
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          // Visualizza un indicatore di caricamento o un testo di attesa
          return Stack(
            alignment: Alignment.center,
            children: <Widget>[
              // Sfondo con un'immagine
              Container(
                decoration: const BoxDecoration(
                  image: DecorationImage(
                    image: AssetImage(
                        'assets/images/sfondoapplicazionenuovodue.png'),
                    // Sostituisci con il percorso dell'immagine di sfondo desiderata
                    fit: BoxFit
                        .cover, // Puoi personalizzare come l'immagine di sfondo si adatta al contenitore
                  ),
                ),
              ),

              // CircularProgressIndicator al centro
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(Colors.yellow),
                // Personalizza il colore
                strokeWidth: 4.0, // Personalizza lo spessore
              ),
            ],
          );
          // Esempio con indicatore di caricamento
        } else {
          // Dopo il ritardo, esegui il build del tuo widget
          return Scaffold(
            appBar: AppBar(
              title: const Text('Home'),
              backgroundColor: const Color(0xeaeace00),
              titleTextStyle: const TextStyle(color: Colors.black),
            ),
            drawer: Drawer(
              child: ListView(
                children: <Widget>[
                  DrawerHeader(
                    decoration: const BoxDecoration(
                      color: Color(0xeaeace00),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        ClipOval(
                          child: Image.network(
                            immagineProfiloUrl.toString(),
                            width: 100.0,
                            height: 100.0,
                            fit: BoxFit.scaleDown,
                          ),
                        ),
                        const SizedBox(height: 8.0),
                        Text(
                          "${userData!['username'] ?? 'Nessun username'}",
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                  ListTile(
                    title: const Text('Modifica Profilo'),
                    leading: const Icon(Icons.person),
                    onTap: () {
                      ScaffoldMessenger.of(context).removeCurrentSnackBar();
                      ScaffoldMessenger.of(this.context).showSnackBar(
                        SnackBar(
                          content: const Text('COMING SOON...', textAlign: TextAlign.center,),
                          duration: Duration(seconds: 3), // Durata dello snackbar
                          action: SnackBarAction(
                            label: 'Chiudi',
                            onPressed: () {
                              // Azione da eseguire quando si preme il pulsante "Chiudi"
                              ScaffoldMessenger.of(context).hideCurrentSnackBar();
                            },
                          ),
                        ),
                      );
                    },
                  ),
                  ListTile(
                    title: const Text('Guardaroba Personale'),
                    leading: const Icon(Icons.cabin_sharp),
                    onTap: () {
                      // Aggiungi l'azione per l'elemento 2 qui
                    },
                  ),
                  ListTile(
                    title: const Text('Logout'),
                    leading: const Icon(Icons.logout),
                    onTap: () {
                      _handleLogout(context);
                    },
                  ),
                  // Aggiungi ulteriori voci di menu se necessario
                ],
              ),
            ),
            body: Column(
              // Wrappa tutto in un Column
              children: <Widget>[
                if (_currentIndex == 0) // Mostra solo quando _currentIndex è 0
                  Expanded(
                    child: ListView.builder(
                      itemCount: consiglio.length,
                      itemBuilder: (BuildContext context, int index) {
                        final elemento = consiglio[index];
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 15.0),
                          child: Card(
                            elevation: 4.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Card(
                                        elevation: 0.0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(25.0),
                                        ),
                                        child: Container(
                                          width: 48.0,
                                          height: 48.0,
                                          margin:
                                              const EdgeInsets.only(top: 10.0),
                                          child: ClipOval(
                                            child: FutureBuilder<String>(
                                              future: getImageUrl(elemento.uid),
                                              // Ottieni l'URL dell'immagine in modo asincrono
                                              builder: (BuildContext context,
                                                  AsyncSnapshot<String>
                                                      snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return const Text("");
                                                } else if (snapshot.hasError) {
                                                  return Text(
                                                      'Errore: ${snapshot.error}');
                                                } else {
                                                  // L'URL dell'immagine è pronto, visualizzalo
                                                  return Image.network(
                                                    snapshot.data as String,
                                                    // Utilizza il valore della Future<String> ottenuto dal FutureBuilder
                                                    width: 50.0,
                                                    height: 50.0,
                                                    fit: BoxFit.cover,
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10.0),
                                      FutureBuilder<String>(
                                        future: getUsername(elemento.uid),
                                        builder: (BuildContext context,
                                            AsyncSnapshot<String> snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Text(
                                              'Caricamento...',
                                              // Testo di attesa
                                              style: TextStyle(
                                                fontSize: 16.0,
                                              ),
                                            );
                                          } else {
                                            if (snapshot.hasError ||
                                                snapshot.data == null) {
                                              return const Text(
                                                'Nessun username',
                                                // Oppure un messaggio di errore
                                                style: TextStyle(
                                                  fontSize: 16.0,
                                                ),
                                              );
                                            } else {
                                              return Text(
                                                snapshot.data!,
                                                style: const TextStyle(
                                                  fontSize: 16.0,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10.0),
                                  Row(
                                    children: [
                                      const Icon(Icons.article),
                                      const SizedBox(width: 8.0),
                                      Text(
                                        elemento.desc,
                                        // Sostituisci con la descrizione desiderata
                                        style: const TextStyle(
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10.0),
                                  Row(
                                    children: [
                                      const Icon(Icons.calendar_month),
                                      const SizedBox(width: 8.0),
                                      Text(
                                        elemento.dataEvento,
                                        // Sostituisci con la data dell'evento desiderata
                                        style: const TextStyle(
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10.0),
                                  Row(
                                    children: [
                                      Image.asset(
                                        'assets/images/t_shirt.png',
                                        // Sostituisci con il percorso dell'immagine desiderata
                                        width: 24.0,
                                        height: 24.0,
                                      ),
                                      const SizedBox(width: 8.0),
                                      Text(
                                        elemento.temaEvento,
                                        // Sostituisci con il tema dell'evento desiderato
                                        style: const TextStyle(
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10.0),
                                  Center(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          primary: const Color(0xEAEACE00),
                                          textStyle: const TextStyle(
                                              color: Colors
                                                  .black) // Imposta il colore del pulsante a rosso
                                          ),
                                      onPressed: () {
                                        // Aggiungi l'azione desiderata quando il pulsante viene premuto
                                      },
                                      child: const Text(
                                        'GUARDA I COMMENTI',
                                        style: TextStyle(
                                            fontSize: 10.0,
                                            color: Colors.black),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10.0),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            "${elemento.dataCreazione} - ",
                                            // Sostituisci con la data di creazione desiderata
                                            style: const TextStyle(
                                              fontSize: 12.0,
                                            ),
                                          ),
                                          Text(
                                            elemento.oraCreazione,
                                            // Sostituisci con l'ora di creazione desiderata
                                            style: const TextStyle(
                                              fontSize: 12.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (_currentIndex == 1)
                  Expanded(
                    child: ListView.builder(
                      itemCount: comments.length,
                      itemBuilder: (BuildContext context, int index) {
                        final commento = comments[index];
                        return Container(
                          width: double.infinity,
                          margin: const EdgeInsets.symmetric(horizontal: 15.0),
                          child: Card(
                            elevation: 4.0,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(15.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Card(
                                        elevation: 0.0,
                                        shape: RoundedRectangleBorder(
                                          borderRadius:
                                              BorderRadius.circular(25.0),
                                        ),
                                        child: Container(
                                          width: 48.0,
                                          height: 48.0,
                                          margin:
                                              const EdgeInsets.only(top: 10.0),
                                          child: ClipOval(
                                            child: FutureBuilder<String>(
                                              future: getImageUrl(commento.uid),
                                              // Ottieni l'URL dell'immagine in modo asincrono
                                              builder: (BuildContext context,
                                                  AsyncSnapshot<String>
                                                      snapshot) {
                                                if (snapshot.connectionState ==
                                                    ConnectionState.waiting) {
                                                  return const Text("");
                                                } else if (snapshot.hasError) {
                                                  return Text(
                                                      'Errore: ${snapshot.error}');
                                                } else {
                                                  // L'URL dell'immagine è pronto, visualizzalo
                                                  return Image.network(
                                                    snapshot.data as String,
                                                    // Utilizza il valore della Future<String> ottenuto dal FutureBuilder
                                                    width: 50.0,
                                                    height: 50.0,
                                                    fit: BoxFit.cover,
                                                  );
                                                }
                                              },
                                            ),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 10.0),
                                      FutureBuilder<String>(
                                        future: getUsername(commento.uid),
                                        builder: (BuildContext context,
                                            AsyncSnapshot<String> snapshot) {
                                          if (snapshot.connectionState ==
                                              ConnectionState.waiting) {
                                            return const Text(
                                              'Caricamento...',
                                              // Testo di attesa
                                              style: TextStyle(
                                                fontSize: 16.0,
                                              ),
                                            );
                                          } else {
                                            if (snapshot.hasError ||
                                                snapshot.data == null) {
                                              return const Text(
                                                'Nessun username',
                                                // Oppure un messaggio di errore
                                                style: TextStyle(
                                                  fontSize: 16.0,
                                                ),
                                              );
                                            } else {
                                              return Text(
                                                snapshot.data!,
                                                style: const TextStyle(
                                                  fontSize: 16.0,
                                                ),
                                              );
                                            }
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10.0),
                                  Row(
                                    children: [
                                      const Icon(Icons.article),
                                      const SizedBox(width: 8.0),
                                      Text(
                                        commento.desc,
                                        // Sostituisci con la descrizione desiderata
                                        style: const TextStyle(
                                          fontSize: 14.0,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 10.0),
                                  Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: commento.img.map((scelta) {
                                      return Row(
                                        children: [
                                          Radio<String>(
                                            value: scelta,
                                            groupValue: selectedScelta,
                                            // Usa una variabile per tenere traccia della scelta selezionata
                                            onChanged: (String? value) {
                                              setState(() {
                                                selectedScelta = value;
                                              });
                                              const SizedBox(height: 10);
                                            },

                                          ),
                                          FutureBuilder<String>(
                                            future: getImageUrlSondaggio(commento.postId, scelta),
                                            builder: (context, snapshot) {
                                              if (snapshot.connectionState ==
                                                  ConnectionState.waiting) {
                                                // Visualizza un indicatore di caricamento se la chiamata è ancora in corso
                                                return Text("wait");
                                              } else if (snapshot.hasError) {
                                                // Gestisci eventuali errori
                                                return Text(
                                                    'Errore durante il caricamento dell\'immagine');
                                              } else if (!snapshot.hasData) {
                                                // Nessun dato disponibile
                                                return Text(
                                                    'Nessun URL immagine disponibile');
                                              } else {
                                                // Ottieni l'URL dell'immagine dal Future
                                                String imageUrl =
                                                    snapshot.data!;
                                                const SizedBox(height: 10,);
                                                // Utilizza l'URL dell'immagine nell'Image.network
                                                return Column(
                                                  children: [
                                                    Image.network(imageUrl, width: 150),
                                                    const SizedBox(height: 10),
                                                  ],
                                                );
                                              }

                                            },
                                          ),
                                          const SizedBox(height: 10),
                                        ],

                                      );

                                    }).toList(),
                                  ),
                                  const SizedBox(height: 10.0),
                                  Center(
                                    child: ElevatedButton(
                                      style: ElevatedButton.styleFrom(
                                          primary: const Color(0xEAEACE00),
                                          textStyle: const TextStyle(
                                              color: Colors
                                                  .black) // Imposta il colore del pulsante a rosso
                                          ),
                                      onPressed: () {
                                        // Aggiungi l'azione desiderata quando il pulsante viene premuto
                                      },
                                      child: const Text(
                                        'VOTA',
                                        style: TextStyle(
                                            fontSize: 10.0,
                                            color: Colors.black),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 10.0),
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          Text(
                                            "${commento.dataCreazione} - ",
                                            // Sostituisci con la data di creazione desiderata
                                            style: const TextStyle(
                                              fontSize: 12.0,
                                            ),
                                          ),
                                          Text(
                                            commento.oraCreazione,
                                            // Sostituisci con l'ora di creazione desiderata
                                            style: const TextStyle(
                                              fontSize: 12.0,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                if (_currentIndex > 1) _pages[_currentIndex],
                // Visualizza la pagina corrente se _currentIndex non è 0
              ],
            ),
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _currentIndex,
              onTap: (int index) {
                setState(() {
                  _currentIndex = index; // Cambia la pagina corrente
                });
              },
              items: const [
                BottomNavigationBarItem(
                  icon: Icon(Icons.help),
                  label: 'Consigli',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.message),
                  label: 'Commenti',
                ),
                BottomNavigationBarItem(
                  icon: Icon(Icons.search),
                  label: 'Search',
                ),
                // Aggiungi altre voci per le pagine qui
              ],
            ),
          );
        }
      },
    );
  }
}
