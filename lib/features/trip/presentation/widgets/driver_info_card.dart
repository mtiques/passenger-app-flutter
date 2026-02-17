import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/entities/trip.dart';

class DriverInfoCard extends ConsumerWidget {
  final Trip trip;

  const DriverInfoCard({
    super.key,
    required this.trip,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final driver = trip.driver;

    if (driver == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Indicador
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Estado del viaje
          _buildStatusBanner(trip.status),
          const SizedBox(height: 24),

          // Info del conductor
          Card(
            elevation: 0,
            color: Colors.grey[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: [
                  // Foto del conductor
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: Colors.blue[100],
                    child: Text(
                      driver.name[0].toUpperCase(),
                      style: const TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),

                  // Datos del conductor
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          driver.name,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          driver.licenseNumber ??
                              'Vehículo no especificado', // ✅ Usar licenseNumber
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            const Icon(Icons.star,
                                color: Colors.amber, size: 16),
                            const SizedBox(width: 4),
                            Text(
                              driver.rating.toStringAsFixed(1),
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[600],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Botones de acción
                  Column(
                    children: [
                      IconButton(
                        onPressed: () => _callDriver(driver.phone),
                        icon: const Icon(Icons.phone),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.green[50],
                          foregroundColor: Colors.green[700],
                        ),
                      ),
                      const SizedBox(height: 8),
                      IconButton(
                        onPressed: () => _messageDriver(driver.id),
                        icon: const Icon(Icons.message),
                        style: IconButton.styleFrom(
                          backgroundColor: Colors.blue[50],
                          foregroundColor: Colors.blue[700],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Info del viaje
          Card(
            elevation: 0,
            color: Colors.grey[50],
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLocationRow(
                    icon: Icons.trip_origin,
                    color: Colors.green,
                    label: 'Origen',
                    address: trip.origin.address,
                  ),
                  const Padding(
                    padding: EdgeInsets.only(left: 12, top: 4, bottom: 4),
                    child: Icon(
                      Icons.more_vert,
                      size: 20,
                      color: Colors.grey,
                    ),
                  ),
                  _buildLocationRow(
                    icon: Icons.location_on,
                    color: Colors.red,
                    label: 'Destino',
                    address: trip.destination.address,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Precio estimado
          if (trip.estimatedPrice != null)
            Card(
              elevation: 0,
              color: Colors.green[50],
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Precio estimado',
                      style: TextStyle(fontSize: 16),
                    ),
                    Text(
                      '\$${trip.estimatedPrice!.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[700],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          const SizedBox(height: 16),

          // Botón de cancelar
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () => _showCancelDialog(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: Colors.red,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text('Cancelar viaje'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBanner(TripStatus status) {
    String text;
    Color color;
    IconData icon;

    switch (status) {
      case TripStatus.accepted:
        text = 'Conductor asignado';
        color = Colors.blue;
        icon = Icons.check_circle;
        break;
      case TripStatus.driverArriving:
        text = 'Conductor en camino';
        color = Colors.orange;
        icon = Icons.directions_car;
        break;
      case TripStatus.inProgress:
        text = 'Viaje en progreso';
        color = Colors.green;
        icon = Icons.navigation;
        break;
      default:
        text = 'Viaje activo';
        color = Colors.blue;
        icon = Icons.info;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, color: color),
          const SizedBox(width: 12),
          Text(
            text,
            style: TextStyle(
              color: color,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLocationRow({
    required IconData icon,
    required Color color,
    required String label,
    required String? address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 24),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.grey[600],
                ),
              ),
              Text(
                address ?? 'Sin dirección', // ✅ Maneja el null
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _callDriver(String phone) {
    // Implementar llamada
    debugPrint('Calling driver: $phone');
  }

  void _messageDriver(int driverId) {
    // Implementar mensajes
    debugPrint('Messaging driver: $driverId');
  }

  void _showCancelDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar viaje'),
        content:
            const Text('¿Estás seguro de que quieres cancelar este viaje?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('No'),
          ),
          TextButton(
            onPressed: () {
              // Aquí implementarás la cancelación
              Navigator.pop(context);
            },
            child: const Text(
              'Sí, cancelar',
              style: TextStyle(color: Colors.red),
            ),
          ),
        ],
      ),
    );
  }
}
