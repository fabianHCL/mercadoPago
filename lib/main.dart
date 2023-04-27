import 'package:flutter/material.dart';
import 'package:mercadopago_sdk/mercadopago_sdk.dart';
import 'package:probando/utils/globals.dart' as globals;
import 'dart:js' as js;

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Flutter Demo',
      home: const MyHomePage(title: 'Flutter Demo Home Page'),
    );
  }
}

class MyHomePage extends StatefulWidget {
  const MyHomePage({super.key, required this.title});

  final String title;

  @override
  State<MyHomePage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<MyHomePage> {
  // var mp = MP(globals.mpClientID, globals.mpClientSecret);
  var mp = MP.fromAccessToken(globals.testAccessTokken);

  List<Map<String, dynamic>> carrito = [
    {'evento': 'Evento de cafe', 'cantidadTickets': 8, 'precioTotal': 5},
    {'evento': 'Expo Cafe', 'cantidadTickets': 2, 'precioTotal': 2},
    {'evento': 'Rock in Coffe', 'cantidadTickets': 5, 'precioTotal': 5}
  ];

  @override
  Widget build(BuildContext context) {
    Future<Map<String, dynamic>> armarPreferencia() async {
      List<Map<String, dynamic>> items = [];

      carrito.forEach((producto) {
        var item = {
          "title": producto['evento'],
          "quantity": producto['cantidadTickets'],
          "currency_id": "USD",
          "unit_price": producto['precioTotal'] / producto['cantidadTickets']
        };
        items.add(item);
      });

      var preference = {
        "items": items,
        // "payer": {
        //   "name": 'Fabian',
        //   "surname": "Carrion",
        //   "email": "fabian.carrion@sellside.cl"
        // },
        // "payment_methods": {
        //   "excluded_payment_types": [
        //     {"id": "ticket"},
        //     {"id": "efecty"}
        //   ]
        // }
      };

      var result = await mp.createPreference(preference);

      return result;
    }

    Future<void> verificarEstadoPago(String preferenceID) async {
      try {
        var paymentInfo = await mp.getPayment(preferenceID);
        print(paymentInfo);
        if (paymentInfo != null && paymentInfo['response'] != null) {
          var paymentStatus = paymentInfo['response']['status'];
          showDialog(
            context: context,
            builder: (BuildContext context) {
              return AlertDialog(
                title: Text('Estado del pago'),
                content: Text('El pago se encuentra en estado $paymentStatus'),
                actions: [
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    child: Text('Cerrar'),
                  ),
                ],
              );
            },
          );
        } else {
          throw Exception('No se recibió una respuesta válida del servidor');
        }
      } catch (e) {
        print(e);
        showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text('Error'),
              content: Text(
                  'Hubo un error al verificar el estado del pago. Por favor, inténtelo de nuevo más tarde.'),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Cerrar'),
                ),
              ],
            );
          },
        );
      }
    }

    Future<void> ejecutarMercadoPago() async {
      var result = await armarPreferencia();
      if (result != null) {
        var preferenceID = result['response']['id'];
        var urlMercadoPago =
            'https://sandbox.mercadopago.com.co/checkout/v1/redirect?pref_id=$preferenceID';
        js.context.callMethod('open', [urlMercadoPago, '_blank']);
        await verificarEstadoPago(preferenceID);
      }
    }

    return Scaffold(
        body: Column(
      children: [
        Expanded(
          flex: 1,
          child: ListView.builder(
            itemCount: carrito.length,
            itemBuilder: (BuildContext context, int index) {
              final item = carrito[index];
              return Padding(
                padding: const EdgeInsets.all(8.0),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[300],
                  ),
                  child: ListTile(
                    title: Text(item['evento']),
                    subtitle:
                        Text('Cantidad de tickets: ${item['cantidadTickets']}'),
                    trailing: Text('\$${item['precioTotal']}'),
                  ),
                ),
              );
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.all(8.0),
          child: ElevatedButton(
            onPressed: () {
              // Add your button onPressed code here!
              ejecutarMercadoPago();
            },
            child: Text('Generar compra'),
          ),
        ),
      ],
    ));
  }
}
