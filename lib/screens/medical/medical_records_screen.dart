import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../models/medical_record.dart';
import '../../models/pet.dart';
import '../../services/medical_service.dart';
import '../../services/pet_service.dart';
import '../../utils/theme.dart';
import 'add_medical_record_screen.dart';

class MedicalRecordsScreen extends StatefulWidget {
  final String petId;

  const MedicalRecordsScreen({super.key, required this.petId});

  @override
  State<MedicalRecordsScreen> createState() => _MedicalRecordsScreenState();
}

class _MedicalRecordsScreenState extends State<MedicalRecordsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final MedicalService _medicalService = MedicalService();
  final PetService _petService = PetService();
  List<MedicalRecord> _records = [];
  Pet? _pet;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 5, vsync: this);
    _loadData();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      _pet = await _petService.getPet(widget.petId);
      _records = await _medicalService.getMedicalRecords(widget.petId);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading data: $e')),
        );
      }
    }
    setState(() => _isLoading = false);
  }

  Future<void> _loadRecords() async {
    try {
      _records = await _medicalService.getMedicalRecords(widget.petId);
      setState(() {});
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading records: $e')),
        );
      }
    }
  }

  List<MedicalRecord> _filterRecords(MedicalRecordType? type) {
    if (type == null) return _records;
    return _records.where((r) => r.type == type).toList();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    if (_pet == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Health Records')),
        body: const Center(child: Text('Pet not found')),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('${_pet!.name}\'s Health'),
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppTheme.primaryColor,
          unselectedLabelColor: AppTheme.textSecondary,
          indicatorColor: AppTheme.primaryColor,
          tabs: const [
            Tab(text: 'All'),
            Tab(text: 'Vaccinations'),
            Tab(text: 'Medications'),
            Tab(text: 'Conditions'),
            Tab(text: 'Visits'),
          ],
        ),
      ),
      body: TabBarView(
              controller: _tabController,
              children: [
                _buildRecordsList(null),
                _buildRecordsList(MedicalRecordType.vaccination),
                _buildRecordsList(MedicalRecordType.medication),
                _buildRecordsList(MedicalRecordType.condition),
                _buildVisitsList(),
              ],
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddRecordDialog(),
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildRecordsList(MedicalRecordType? type) {
    final records = _filterRecords(type);

    if (records.isEmpty) {
      return _buildEmptyState(type);
    }

    return RefreshIndicator(
      onRefresh: _loadRecords,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: records.length,
        itemBuilder: (context, index) {
          final record = records[index];
          return _MedicalRecordCard(
            record: record,
            onTap: () => _showRecordDetails(record),
            onDelete: () => _deleteRecord(record),
          );
        },
      ),
    );
  }

  Widget _buildVisitsList() {
    final visits = _records
        .where((r) =>
            r.type == MedicalRecordType.vetVisit ||
            r.type == MedicalRecordType.groomingVisit)
        .toList();

    if (visits.isEmpty) {
      return _buildEmptyState(MedicalRecordType.vetVisit);
    }

    return RefreshIndicator(
      onRefresh: _loadRecords,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: visits.length,
        itemBuilder: (context, index) {
          final record = visits[index];
          return _MedicalRecordCard(
            record: record,
            onTap: () => _showRecordDetails(record),
            onDelete: () => _deleteRecord(record),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState(MedicalRecordType? type) {
    String message;
    IconData icon;

    switch (type) {
      case MedicalRecordType.vaccination:
        message = 'No vaccinations recorded';
        icon = Icons.vaccines;
        break;
      case MedicalRecordType.medication:
        message = 'No medications recorded';
        icon = Icons.medication;
        break;
      case MedicalRecordType.condition:
        message = 'No conditions recorded';
        icon = Icons.healing;
        break;
      case MedicalRecordType.vetVisit:
        message = 'No visits recorded';
        icon = Icons.local_hospital;
        break;
      default:
        message = 'No medical records yet';
        icon = Icons.medical_services;
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 64,
              color: AppTheme.primaryColor.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 16),
            Text(
              message,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Tap + to add a record',
              style: TextStyle(color: AppTheme.textSecondary),
            ),
          ],
        ),
      ),
    );
  }

  void _showAddRecordDialog() {
    if (_pet == null) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => AddMedicalRecordScreen(petId: widget.petId),
      ),
    ).then((_) => _loadRecords());
  }

  void _showRecordDetails(MedicalRecord record) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: AppTheme.dividerColor,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: _getRecordColor(record.type).withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      _getRecordIcon(record.type),
                      color: _getRecordColor(record.type),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          record.title,
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Text(
                          _getRecordTypeName(record.type),
                          style: TextStyle(
                            color: _getRecordColor(record.type),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Expanded(
                child: ListView(
                  controller: scrollController,
                  children: [
                    _DetailRow(
                      label: 'Date',
                      value: DateFormat('MMMM d, y').format(record.date),
                    ),
                    if (record.provider != null)
                      _DetailRow(label: 'Provider', value: record.provider!),
                    if (record.description != null)
                      _DetailRow(
                          label: 'Notes', value: record.description!),
                    if (record.dosage != null)
                      _DetailRow(label: 'Dosage', value: record.dosage!),
                    if (record.frequency != null)
                      _DetailRow(label: 'Frequency', value: record.frequency!),
                    if (record.nextDueDate != null)
                      _DetailRow(
                        label: 'Next Due',
                        value:
                            DateFormat('MMMM d, y').format(record.nextDueDate!),
                      ),
                    const SizedBox(height: 24),
                    Row(
                      children: [
                        Expanded(
                          child: OutlinedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              _deleteRecord(record);
                            },
                            icon: const Icon(Icons.delete),
                            label: const Text('Delete'),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppTheme.errorColor,
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: () {
                              Navigator.pop(context);
                              // TODO: Edit record
                            },
                            icon: const Icon(Icons.edit),
                            label: const Text('Edit'),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _deleteRecord(MedicalRecord record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Record?'),
        content: Text('Are you sure you want to delete "${record.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: AppTheme.errorColor),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _medicalService.deleteMedicalRecord(record.id);
        await _loadRecords();
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Record deleted')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Error deleting record: $e')),
          );
        }
      }
    }
  }

  IconData _getRecordIcon(MedicalRecordType type) {
    switch (type) {
      case MedicalRecordType.vaccination:
        return Icons.vaccines;
      case MedicalRecordType.medication:
        return Icons.medication;
      case MedicalRecordType.allergy:
        return Icons.warning_amber;
      case MedicalRecordType.condition:
        return Icons.healing;
      case MedicalRecordType.vetVisit:
        return Icons.local_hospital;
      case MedicalRecordType.groomingVisit:
        return Icons.content_cut;
      case MedicalRecordType.surgery:
        return Icons.medical_services;
      case MedicalRecordType.labResult:
        return Icons.science;
    }
  }

  Color _getRecordColor(MedicalRecordType type) {
    switch (type) {
      case MedicalRecordType.vaccination:
        return Colors.blue;
      case MedicalRecordType.medication:
        return Colors.purple;
      case MedicalRecordType.allergy:
        return Colors.orange;
      case MedicalRecordType.condition:
        return Colors.red;
      case MedicalRecordType.vetVisit:
        return Colors.teal;
      case MedicalRecordType.groomingVisit:
        return Colors.pink;
      case MedicalRecordType.surgery:
        return Colors.red;
      case MedicalRecordType.labResult:
        return Colors.green;
    }
  }

  String _getRecordTypeName(MedicalRecordType type) {
    switch (type) {
      case MedicalRecordType.vaccination:
        return 'Vaccination';
      case MedicalRecordType.medication:
        return 'Medication';
      case MedicalRecordType.allergy:
        return 'Allergy';
      case MedicalRecordType.condition:
        return 'Condition';
      case MedicalRecordType.vetVisit:
        return 'Vet Visit';
      case MedicalRecordType.groomingVisit:
        return 'Grooming';
      case MedicalRecordType.surgery:
        return 'Surgery';
      case MedicalRecordType.labResult:
        return 'Lab Result';
    }
  }
}

class _MedicalRecordCard extends StatelessWidget {
  final MedicalRecord record;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _MedicalRecordCard({
    required this.record,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: AppTheme.thickBorder,
        boxShadow: AppTheme.softShadow,
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(24),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: _getColor().withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(_getIcon(), color: _getColor()),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      record.title,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.calendar_today,
                          size: 14,
                          color: AppTheme.textLight,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          DateFormat('MMM d, y').format(record.date),
                          style: TextStyle(
                            color: AppTheme.textSecondary,
                            fontSize: 13,
                          ),
                        ),
                        if (record.nextDueDate != null) ...[
                          const SizedBox(width: 12),
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 2,
                            ),
                            decoration: BoxDecoration(
                              color: record.isDue
                                  ? AppTheme.errorColor.withValues(alpha: 0.1)
                                  : AppTheme.warningColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(
                              record.isDue ? 'Due!' : 'Upcoming',
                              style: TextStyle(
                                color: record.isDue
                                    ? AppTheme.errorColor
                                    : AppTheme.warningColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.chevron_right,
                color: AppTheme.textLight,
              ),
            ],
          ),
        ),
      ),
    );
  }

  IconData _getIcon() {
    switch (record.type) {
      case MedicalRecordType.vaccination:
        return Icons.vaccines;
      case MedicalRecordType.medication:
        return Icons.medication;
      case MedicalRecordType.allergy:
        return Icons.warning_amber;
      case MedicalRecordType.condition:
        return Icons.healing;
      case MedicalRecordType.vetVisit:
        return Icons.local_hospital;
      case MedicalRecordType.groomingVisit:
        return Icons.content_cut;
      case MedicalRecordType.surgery:
        return Icons.medical_services;
      case MedicalRecordType.labResult:
        return Icons.science;
    }
  }

  Color _getColor() {
    switch (record.type) {
      case MedicalRecordType.vaccination:
        return Colors.blue;
      case MedicalRecordType.medication:
        return Colors.purple;
      case MedicalRecordType.allergy:
        return Colors.orange;
      case MedicalRecordType.condition:
        return Colors.red;
      case MedicalRecordType.vetVisit:
        return Colors.teal;
      case MedicalRecordType.groomingVisit:
        return Colors.pink;
      case MedicalRecordType.surgery:
        return Colors.red;
      case MedicalRecordType.labResult:
        return Colors.green;
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;

  const _DetailRow({
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              color: AppTheme.textSecondary,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
