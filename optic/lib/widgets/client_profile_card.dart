import '../models/client.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../localization/app_strings.dart';

class ClientProfileCard extends StatelessWidget {
  final Client client;
  const ClientProfileCard({super.key, required this.client});

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text("${client.firstName} ${client.lastName}").semiBold(),
          const SizedBox(height: 8),
          Text('${AppStrings.cardClientProfileDob} ${client.dob.toLocal().toString().split(' ')[0]}').muted(),
          Text('${AppStrings.cardClientProfileGender} ${client.gender}').muted(),
          Text('${AppStrings.cardClientProfileBloodGroup} ${client.bloodGroup}').muted(),
          Text('${AppStrings.cardClientProfileInsurance} ${client.insurance.isEmpty ? AppStrings.cardClientProfileNoInsurance : client.insurance}').muted(),
        ],
      ),
    );
  }
}
