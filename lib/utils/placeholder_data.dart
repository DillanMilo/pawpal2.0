// Placeholder data for demo and testing purposes
class PlaceholderData {
  // Sample Pets
  static final List<Map<String, dynamic>> samplePets = [
    {
      'id': 'demo-pet-1',
      'name': 'Luna',
      'species': 'Dog',
      'breed': 'Golden Retriever',
      'gender': 'Female',
      'age': '3 years',
      'weight': 28.5,
      'photoUrl': null,
      'emoji': '🐕',
    },
    {
      'id': 'demo-pet-2',
      'name': 'Mochi',
      'species': 'Cat',
      'breed': 'Scottish Fold',
      'gender': 'Male',
      'age': '2 years',
      'weight': 4.2,
      'photoUrl': null,
      'emoji': '🐱',
    },
    {
      'id': 'demo-pet-3',
      'name': 'Sunny',
      'species': 'Bird',
      'breed': 'Cockatiel',
      'gender': 'Male',
      'age': '1 year',
      'weight': 0.1,
      'photoUrl': null,
      'emoji': '🐦',
    },
  ];

  // Sample Reminders
  static final List<Map<String, dynamic>> sampleReminders = [
    {
      'title': 'Luna\'s Vaccination',
      'subtitle': 'Annual booster shot',
      'time': 'Tomorrow, 10:00 AM',
      'type': 'vaccination',
      'color': 0xFFFF6B6B,
      'icon': '💉',
    },
    {
      'title': 'Mochi\'s Grooming',
      'subtitle': 'Monthly grooming session',
      'time': 'Friday, 2:00 PM',
      'type': 'grooming',
      'color': 0xFFB8B8FF,
      'icon': '✂️',
    },
    {
      'title': 'Sunny\'s Vet Checkup',
      'subtitle': 'Routine health check',
      'time': 'Next Monday, 11:00 AM',
      'type': 'vet',
      'color': 0xFF4ECDC4,
      'icon': '🏥',
    },
  ];

  // Sample Vets
  static final List<Map<String, dynamic>> sampleVets = [
    {
      'name': 'Happy Paws Veterinary',
      'address': '123 Pet Street, Downtown',
      'rating': 4.8,
      'reviews': 256,
      'distance': '0.8 mi',
      'isOpen': true,
      'specialties': ['General Care', 'Surgery', 'Dental'],
      'image': null,
    },
    {
      'name': 'City Animal Hospital',
      'address': '456 Care Avenue, Midtown',
      'rating': 4.6,
      'reviews': 189,
      'distance': '1.2 mi',
      'isOpen': true,
      'specialties': ['Emergency', '24/7 Care', 'Exotic Pets'],
      'image': null,
    },
    {
      'name': 'Whiskers & Tails Clinic',
      'address': '789 Furry Lane, Uptown',
      'rating': 4.9,
      'reviews': 312,
      'distance': '2.1 mi',
      'isOpen': false,
      'specialties': ['Cats Only', 'Behavior', 'Nutrition'],
      'image': null,
    },
  ];

  // Sample Groomers
  static final List<Map<String, dynamic>> sampleGroomers = [
    {
      'name': 'Pampered Pets Spa',
      'address': '321 Grooming Blvd',
      'rating': 4.9,
      'reviews': 423,
      'distance': '0.5 mi',
      'isOpen': true,
      'services': ['Bath', 'Haircut', 'Nail Trim', 'Teeth Cleaning'],
      'priceRange': '\$\$',
    },
    {
      'name': 'Fluffy Styles',
      'address': '654 Pet Fashion St',
      'rating': 4.7,
      'reviews': 198,
      'distance': '1.8 mi',
      'isOpen': true,
      'services': ['Full Grooming', 'De-shedding', 'Styling'],
      'priceRange': '\$\$\$',
    },
  ];

  // Sample Pet Stores
  static final List<Map<String, dynamic>> sampleStores = [
    {
      'name': 'Pet Paradise',
      'address': '111 Shopping Center',
      'rating': 4.5,
      'reviews': 567,
      'distance': '0.3 mi',
      'isOpen': true,
      'categories': ['Food', 'Toys', 'Accessories', 'Health'],
    },
    {
      'name': 'Furry Friends Market',
      'address': '222 Main Street',
      'rating': 4.7,
      'reviews': 234,
      'distance': '1.1 mi',
      'isOpen': true,
      'categories': ['Premium Food', 'Organic Treats', 'Eco-Friendly'],
    },
  ];

  // Activity stats for demo
  static const Map<String, dynamic> sampleStats = {
    'currentStreak': 7,
    'totalPoints': 2450,
    'activitiesThisWeek': 12,
    'totalActivities': 156,
    'weeklyGoal': 15,
    'weeklyProgress': 0.8,
  };

  // Weekly activity data for chart
  static final List<Map<String, dynamic>> weeklyActivity = [
    {'day': 'Mon', 'minutes': 45, 'activities': 2},
    {'day': 'Tue', 'minutes': 60, 'activities': 3},
    {'day': 'Wed', 'minutes': 30, 'activities': 1},
    {'day': 'Thu', 'minutes': 75, 'activities': 3},
    {'day': 'Fri', 'minutes': 50, 'activities': 2},
    {'day': 'Sat', 'minutes': 90, 'activities': 4},
    {'day': 'Sun', 'minutes': 40, 'activities': 2},
  ];

  // Quick tips for pet care
  static final List<Map<String, String>> petTips = [
    {
      'title': 'Hydration Reminder',
      'tip': 'Make sure your pet has fresh water available at all times!',
      'emoji': '💧',
    },
    {
      'title': 'Exercise Time',
      'tip': 'Dogs need at least 30 minutes of exercise daily.',
      'emoji': '🏃',
    },
    {
      'title': 'Dental Health',
      'tip': 'Brush your pet\'s teeth 2-3 times a week.',
      'emoji': '🦷',
    },
    {
      'title': 'Social Time',
      'tip': 'Pets need social interaction for mental health.',
      'emoji': '🤗',
    },
  ];
}
