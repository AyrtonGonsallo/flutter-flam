import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:qr_code_scanner_plus/qr_code_scanner_plus.dart';
import 'dart:convert';

import '../Constants/ApiConstants.dart';

class ScannerPage extends StatefulWidget {
  final int coursId;
  const ScannerPage({super.key, required this.coursId});

  @override
  State<ScannerPage> createState() => _ScannerPageState();
}

class _ScannerPageState extends State<ScannerPage> {
  final GlobalKey qrKey = GlobalKey(debugLabel: 'QR');
  QRViewController? controller;
  bool isScanning = false;
  late String apiUrl;
  late int coursId;
  @override
  void initState() {
    super.initState();
    apiUrl = ApiConstants.baseUrl;
    coursId = widget.coursId; // <- ici
  }


  @override
  void reassemble() {
    super.reassemble();
    controller?.pauseCamera();
    controller?.resumeCamera();
  }

  Future<void> enregistrerPresence(AdherentInfo adherent) async {
    try {
      // Exemple, adapte selon ton API
      final response = await http.post(
        Uri.parse('$apiUrl/api/adherents/upsert_appel'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'status': true,
          'adherentId': adherent.id,
          'coursId': coursId,
        }),
      );
      print("mise a jour appel");
      print(response.body);
      if (response.statusCode == 200) {
        // ✅ Succès
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Présence enregistrée pour ${adherent.nom} ${adherent.prenom}")),
        );
      } else {
        // ❌ Erreur HTTP
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur API (${response.statusCode})")),
        );
      }
    } on SocketException {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Pas de connexion Internet.")),
      );
      throw Exception("Pas de connexion Internet.");

    } on TimeoutException {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Le serveur met trop de temps à répondre.")),
      );
      throw Exception("Le serveur met trop de temps à répondre.");
    } on FormatException {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Réponse invalide du serveur.")),
      );
      throw Exception("Réponse invalide du serveur.");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Erreur inattendue : $e")),
      );
      throw Exception("Erreur inattendue : $e");
    }
  }

  AdherentInfo? _extractAdherentInfoFromQRCode(String data) {
    try {
      final parts = data.split(';');
      int? id;
      String? nom;
      String? prenom;
      String? dojo;

      for (var part in parts) {
        if (part.startsWith('ID:')) {
          id = int.tryParse(part.replaceFirst('ID:', '').trim());
        } else if (part.startsWith('Nom:')) {
          nom = part.replaceFirst('Nom:', '').trim();
        } else if (part.startsWith('Prenom:')) {
          prenom = part.replaceFirst('Prenom:', '').trim();
        } else if (part.startsWith('Dojo:')) {
          dojo = part.replaceFirst('Dojo:', '').trim();
        }
      }

      if (id != null && nom != null && prenom != null && dojo != null) {
        return AdherentInfo(id: id, nom: nom, prenom: prenom, dojo: dojo);
      }
    } catch (e) {
      print('Erreur parsing QR: $e');
    }

    return null;
  }

  void _onQRViewCreated2(QRViewController controller) {
    setState(() {
      this.controller = controller;
    });
    print("📡 Événement reçu du scanner : ss");
    controller.scannedDataStream.listen((scanData) {
      setState(() {
        print("📡 Événement reçu du scanner : $scanData");
      });
    });
  }

  void _onPermissionSet(BuildContext context, QRViewController ctrl, bool p) {
    log('${DateTime.now().toIso8601String()}_onPermissionSet $p');
    if (!p) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('no Permission')),
      );
    }
  }
  void _onQRViewCreated(QRViewController ctrl) {
    print("📡 Événement reçu du scanner : ss1");
    controller = ctrl;
    controller!.scannedDataStream.listen((scanData) async {
      print("📡 Événement reçu du scanner : $scanData");
      if (!isScanning) {
        setState(() => isScanning = true);
        final rawData = scanData.code ?? '';
        final adherentinfo = _extractAdherentInfoFromQRCode(rawData);

        if (adherentinfo != null) {
          await enregistrerPresence(adherentinfo);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("QR code invalide ou ID non trouvé")),
          );
        }

        await Future.delayed(Duration(seconds: 1)); // Petite pause entre les scans
        setState(() => isScanning = false);
      }
    });
  }

  @override
  void dispose() {
    controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // For this example we check how width or tall the device is and change the scanArea and overlay accordingly.
    var scanArea = (MediaQuery.of(context).size.width < 400 ||
        MediaQuery.of(context).size.height < 400)
        ? 250.0
        : 350.0;
    return Scaffold(
      appBar: AppBar(title: Text('Scan QR pour présence'),automaticallyImplyLeading: false,),
      body: Stack(
        children: [
          QRView(
            key: qrKey,
            onQRViewCreated: _onQRViewCreated,
            overlay: QrScannerOverlayShape(
                borderColor: Colors.red,
                borderRadius: 10,
                borderLength: 30,
                borderWidth: 10,
                cutOutSize: scanArea),
            onPermissionSet: (ctrl, p) => _onPermissionSet(context, ctrl, p),
          ),



          // 🔘 Bouton "Fermer"
          Positioned(
            top: 30,
            left: 0,
            right: 0,
            child: Center(
              child: ElevatedButton.icon(
                onPressed: () => Navigator.pop(context,true),
                icon: Icon(Icons.close),
                label: Text("Fermer le scanner"),
              ),
            ),
          ),
        ],
      ),
    );
  }

}


class AdherentInfo {
  final int id;
  final String nom;
  final String prenom;
  final String dojo;

  AdherentInfo({
    required this.id,
    required this.nom,
    required this.prenom,
    required this.dojo,
  });
}
