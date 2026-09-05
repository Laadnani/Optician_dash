import '../models/document.dart';
import 'package:shadcn_flutter/shadcn_flutter.dart';
import '../localization/app_strings.dart';

class DocumentCard extends StatelessWidget {
  final DocumentRecord document;
  const DocumentCard({super.key, required this.document});

  @override
  Widget build(BuildContext context) {
    return Card(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.cardDocumentTitle).semiBold(),
          const SizedBox(height: 8),
          Text('${AppStrings.cardFieldType} ${document.type}').muted(),
          Text('${AppStrings.cardFieldFile} ${document.filePath}').muted(),
          Text('${AppStrings.cardFieldUploaded} ${document.uploadedAt}').muted(),
        ],
      ),
    );
  }
}
