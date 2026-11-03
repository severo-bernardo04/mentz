import 'package:flutter/material.dart';
import 'package:mentz/models/profile_models.dart';

/// Tabela de medidas corporais (rola na horizontal em telas estreitas).
class BodyMeasuresTable extends StatelessWidget {
  final List<BodyMeasure> measures;

  const BodyMeasuresTable({super.key, required this.measures});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: DataTable(
        columnSpacing: 20,
        horizontalMargin: 0,
        headingRowHeight: 36,
        dataRowMinHeight: 36,
        dataRowMaxHeight: 40,
        columns: const [
          DataColumn(label: Text('Data')),
          DataColumn(label: Text('Peito'), numeric: true),
          DataColumn(label: Text('Cintura'), numeric: true),
          DataColumn(label: Text('Quadril'), numeric: true),
          DataColumn(label: Text('Braço'), numeric: true),
          DataColumn(label: Text('Coxa'), numeric: true),
        ],
        rows: [
          for (final m in measures)
            DataRow(
              cells: [
                DataCell(Text(formatShort(m.date))),
                DataCell(Text('${m.chest}')),
                DataCell(Text('${m.waist}')),
                DataCell(Text('${m.hip}')),
                DataCell(Text('${m.arm}')),
                DataCell(Text('${m.thigh}')),
              ],
            ),
        ],
      ),
    );
  }
}