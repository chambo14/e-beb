class CotisationModel {
  final double mensuelCible;
  final double mensuelVerse;
  final double annuelCible;
  final double annuelVerse;

  const CotisationModel({
    required this.mensuelCible,
    required this.mensuelVerse,
    required this.annuelCible,
    required this.annuelVerse,
  });

  double get progressMensuel => (mensuelVerse / mensuelCible).clamp(0.0, 1.0);
  double get progressAnnuel => (annuelVerse / annuelCible).clamp(0.0, 1.0);
  double get restesMois => (mensuelCible - mensuelVerse).clamp(0.0, double.infinity);
  double get resteAnnuel => (annuelCible - annuelVerse).clamp(0.0, double.infinity);

  static const demo = CotisationModel(
    mensuelCible: 30000,
    mensuelVerse: 15000,
    annuelCible: 250000,
    annuelVerse: 105000,
  );
}

class UserModel {
  final String nom;
  final String prenom;
  final String telephone;
  final String cnpsNumero;
  final bool cnpsAJour;
  final double soldeDisponible;
  final double totalRecuMois;
  final double totalDeduitMois;
  final String typeCard; // Basic, Medium, Premium, Premium Plus
  final String cardNumber;
  final String cardExpiry;
  final String matricule;
  final CotisationModel cotisation;

  const UserModel({
    required this.nom,
    required this.prenom,
    required this.telephone,
    required this.cnpsNumero,
    required this.cnpsAJour,
    required this.soldeDisponible,
    required this.totalRecuMois,
    required this.totalDeduitMois,
    required this.typeCard,
    required this.cardNumber,
    required this.cardExpiry,
    required this.matricule,
    required this.cotisation,
  });

  String get fullName => '$prenom $nom';
  String get initials => '${prenom[0]}${nom[0]}'.toUpperCase();

  // Données de démonstration
  static const demo = UserModel(
    nom: 'KONAN',
    prenom: 'Jean-Baptiste',
    telephone: '07 00 00 00 01',
    cnpsNumero: '123456789',
    cnpsAJour: true,
    soldeDisponible: 125000,
    totalRecuMois: 450000,
    totalDeduitMois: 54000,
    typeCard: 'Basic',
    cardNumber: '4534 8612 7843 2271',
    cardExpiry: '07/27',
    matricule: 'MAT124000CI',
    cotisation: CotisationModel.demo,
  );
}

class TransactionModel {
  final String id;
  final String libelle;
  final String description;
  final double montant;
  final bool estCredit;
  final DateTime date;
  final String icone;

  const TransactionModel({
    required this.id,
    required this.libelle,
    required this.description,
    required this.montant,
    required this.estCredit,
    required this.date,
    required this.icone,
  });

  static final demoList = [
    TransactionModel(
      id: '001',
      libelle: 'Paiement reçu',
      description: 'ENTREPRISE ABC SARL',
      montant: 85000,
      estCredit: true,
      date: DateTime(2026, 4, 14, 10, 30),
      icone: '💰',
    ),
    TransactionModel(
      id: '002',
      libelle: 'Déduction CNPS',
      description: 'Cotisation sociale automatique',
      montant: 10200,
      estCredit: false,
      date: DateTime(2026, 4, 14, 10, 31),
      icone: '🏛️',
    ),
    TransactionModel(
      id: '003',
      libelle: 'Déduction AMU',
      description: 'Assurance Maladie Universelle',
      montant: 12000,
      estCredit: false,
      date: DateTime(2026, 4, 14, 10, 31),
      icone: '🏥',
    ),
    TransactionModel(
      id: '004',
      libelle: 'Virement Mobile Money',
      description: 'Orange Money → Compte courant',
      montant: 60300,
      estCredit: false,
      date: DateTime(2026, 4, 14, 10, 32),
      icone: '📲',
    ),
    TransactionModel(
      id: '005',
      libelle: 'Paiement reçu',
      description: 'M. DIALLO Ibrahima',
      montant: 45000,
      estCredit: true,
      date: DateTime(2026, 4, 13, 15, 20),
      icone: '💰',
    ),
    TransactionModel(
      id: '006',
      libelle: 'Épargne logement',
      description: 'Objectif: Achat terrain',
      montant: 5000,
      estCredit: false,
      date: DateTime(2026, 4, 13, 15, 21),
      icone: '🏠',
    ),
    TransactionModel(
      id: '007',
      libelle: 'Paiement reçu',
      description: 'AGENCE CONSEIL PRO',
      montant: 120000,
      estCredit: true,
      date: DateTime(2026, 4, 12, 9, 00),
      icone: '💰',
    ),
    TransactionModel(
      id: '008',
      libelle: 'Déduction CNPS',
      description: 'Cotisation sociale automatique',
      montant: 14400,
      estCredit: false,
      date: DateTime(2026, 4, 12, 9, 01),
      icone: '🏛️',
    ),
    TransactionModel(
      id: '009',
      libelle: 'Transfert compte principal',
      description: 'Virement E-BEB → Ecobank',
      montant: 95000,
      estCredit: false,
      date: DateTime(2026, 4, 11, 17, 45),
      icone: '🏦',
    ),
    TransactionModel(
      id: '010',
      libelle: 'Paiement reçu',
      description: 'Mme KOUASSI Adjoua',
      montant: 30000,
      estCredit: true,
      date: DateTime(2026, 4, 10, 11, 20),
      icone: '💰',
    ),
  ];
}
