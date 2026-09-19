import '../models/app_user.dart';
import '../models/community_post.dart';
import '../models/green_space.dart';
import '../models/notification_item.dart';
import '../models/place_review.dart';
import '../models/story.dart';

final matiGreenSpaces = <GreenSpace>[
  GreenSpace(
    id: 'gs-001',
    name: 'Guang-guang Mangrove Park and Nursery',
    description:
        'A scenic mangrove boardwalk and park in Dahican, valued for coastal defense, habitat preservation, and calm nature walks.',
    category: 'Mangrove Park',
    address: 'Dahican, Mati City, Davao Oriental',
    latitude: 6.9009,
    longitude: 126.2685,
    amenities: ['Boardwalk', 'Shaded paths', 'Photo spots', 'Bird Watching'],
    noiseLevel: CrowdLevel.low,
    crowdDensity: CrowdLevel.low,
    calmFactor: CrowdLevel.high,
    imageUrl: 'assets/images/guang2.jpg',
    destressTag: 'DESTRESS LEVEL: HIGH',
    distanceKm: 1.2,
    tags: ['Quiet Space', 'Nature Walk', 'Boardwalk'],
    reviews: [
      PlaceReview(
        reviewerName: 'Maria J.',
        rating: 4.8,
        comment:
            'The morning breeze here is unmatched. Perfect spot for my 7 AM meditation session. Not too crowded during weekdays.',
        date: DateTime(2026, 8, 18),
      ),
      PlaceReview(
        reviewerName: 'Ryan A.',
        rating: 4.8,
        comment:
            'Great for walking! There are many shaded areas and benches to just sit and enjoy the greenery.',
        date: DateTime(2026, 8, 14),
      ),
      PlaceReview(
        reviewerName: 'Kim D.',
        rating: 4.8,
        comment:
            'Incredible tranquility among the mangroves. My stress melted away completely.',
        date: DateTime(2026, 8, 10),
      ),
    ],
  ),
  GreenSpace(
    id: 'gs-002',
    name: 'Mt. Hamiguitan Range Wildlife Sanctuary',
    description:
        'A UNESCO World Heritage sanctuary offering pristine pygmy forests, pure mountain air, and unmatched tranquil solitude.',
    category: 'Mountain Sanctuary',
    address: 'San Isidro / Mati Border, Davao Oriental',
    latitude: 6.7289,
    longitude: 126.1822,
    amenities: ['Pygmy Forest', 'Fresh Air', 'Trekking', 'Biodiversity'],
    noiseLevel: CrowdLevel.low,
    crowdDensity: CrowdLevel.low,
    calmFactor: CrowdLevel.high,
    imageUrl: 'assets/images/nature_escape_banner.png',
    destressTag: 'NATURAL BREEZE',
    distanceKm: 14.5,
    tags: ['Fresh Air', 'Mountain Walk', 'Sanctuary'],
    reviews: [
      PlaceReview(
        reviewerName: 'Angelo B.',
        rating: 4.9,
        comment:
            'The untouched mountain breeze immediately cleanses all mental clutter. Pure natural harmony.',
        date: DateTime(2026, 8, 22),
      ),
      PlaceReview(
        reviewerName: 'Elena R.',
        rating: 4.9,
        comment:
            'One of the most grounding experiences of my life. Walking among ancient trees is therapeutic.',
        date: DateTime(2026, 8, 15),
      ),
    ],
  ),
  GreenSpace(
    id: 'gs-003',
    name: 'Pujada Bay Lookout',
    description:
        'A viewpoint over Pujada Bay offering panoramic seascape views, calm sea breezes, and fresh air.',
    category: 'Viewpoint',
    address: 'Pujada Bay, Mati City, Davao Oriental',
    latitude: 6.9390,
    longitude: 126.2750,
    amenities: ['Panoramic view', 'Breezy', 'Photo spots'],
    noiseLevel: CrowdLevel.low,
    crowdDensity: CrowdLevel.low,
    calmFactor: CrowdLevel.high,
    imageUrl: 'assets/images/pujada_bay.jpg',
    destressTag: 'COASTAL ESCAPE',
    distanceKm: 4.8,
    tags: ['Sunset View', 'Calm Breeze', 'Panoramic'],
    reviews: [
      PlaceReview(
        reviewerName: 'Angelo B.',
        rating: 4.7,
        comment:
            'Breathtaking panorama. One of the quietest spots in Mati overlooking the blue bay.',
        date: DateTime(2026, 7, 28),
      ),
    ],
  ),
  GreenSpace(
    id: 'gs-004',
    name: 'Dahican Beach',
    description:
        'A wide sandy crescent beach with gentle waves, ideal for relaxing walks, surf meditation, and sunrise views.',
    category: 'Beach',
    address: 'Roxas Boulevard, Dahican, Mati City, Davao Oriental',
    latitude: 6.9091,
    longitude: 126.2657,
    amenities: ['Open sand', 'Sunrise view', 'Breezy', 'Surf spots'],
    noiseLevel: CrowdLevel.moderate,
    crowdDensity: CrowdLevel.moderate,
    calmFactor: CrowdLevel.high,
    imageUrl: 'assets/images/dahican_beach.jpg',
    destressTag: 'OCEAN THERAPY',
    distanceKm: 2.1,
    tags: ['Ocean Waves', 'Surf Meditation', 'Barefoot Walk'],
    reviews: [
      PlaceReview(
        reviewerName: 'Maria J.',
        rating: 4.6,
        comment:
            'The rhythmic sound of ocean waves creates an instant state of deep relaxation.',
        date: DateTime(2026, 8, 17),
      ),
      PlaceReview(
        reviewerName: 'Ryan A.',
        rating: 4.6,
        comment:
            'Sunrise here is something spiritual. Take your shoes off and walk barefoot on the sand.',
        date: DateTime(2026, 8, 11),
      ),
    ],
  ),
  GreenSpace(
    id: 'gs-005',
    name: 'Mati City Freedom Park',
    description:
        'A central public park and plaza with open lawns and shaded seating, close to the city center.',
    category: 'City Park',
    address: 'City Center, Mati City, Davao Oriental',
    latitude: 6.9532,
    longitude: 126.2157,
    amenities: ['Open lawn', 'Seating', 'Easy access', 'Night lights'],
    noiseLevel: CrowdLevel.high,
    crowdDensity: CrowdLevel.moderate,
    calmFactor: CrowdLevel.low,
    imageUrl: 'assets/images/freedom_park.jpg',
    destressTag: 'DESTRESS LEVEL: MODERATE',
    distanceKm: 0.5,
    tags: ['City Oasis', 'Shaded Seating'],
    reviews: [
      PlaceReview(
        reviewerName: 'Leo P.',
        rating: 4.2,
        comment:
            'Convenient and green, but can be lively with city noise during the day. Beautiful at twilight though.',
        date: DateTime(2026, 8, 05),
      ),
    ],
  ),
  GreenSpace(
    id: 'gs-006',
    name: 'Waniban Beach & Cove',
    description:
        'A calm cove beach surrounded by coconut trees, ideal for rest, reflection, and secluded meditation.',
    category: 'Beach',
    address: 'Waniban, Mati City, Davao Oriental',
    latitude: 6.9386,
    longitude: 126.2911,
    amenities: ['Secluded', 'Shaded', 'Calm waters'],
    noiseLevel: CrowdLevel.low,
    crowdDensity: CrowdLevel.low,
    calmFactor: CrowdLevel.high,
    imageUrl: 'assets/images/dahican_beach.jpg',
    destressTag: 'SECLUDED SANCTUARY',
    distanceKm: 7.2,
    tags: ['Calm Cove', 'Coconut Palms', 'Secluded'],
    reviews: [
      PlaceReview(
        reviewerName: 'Sam C.',
        rating: 4.9,
        comment:
            'Calm waters and coconut shade. My favorite place to recharge.',
        date: DateTime(2026, 7, 08),
      ),
    ],
  ),
  GreenSpace(
    id: 'gs-007',
    name: 'Bobon Beach',
    description:
        'A quieter stretch of coastline north of Mati, good for peaceful beach walks and mindful solitude.',
    category: 'Beach',
    address: 'Bobon, Mati City, Davao Oriental',
    latitude: 6.9997,
    longitude: 126.2604,
    amenities: ['Open sand', 'Quiet', 'Nature view'],
    noiseLevel: CrowdLevel.low,
    crowdDensity: CrowdLevel.low,
    calmFactor: CrowdLevel.high,
    imageUrl: 'assets/images/nature_escape_banner.png',
    destressTag: 'PRISTINE CALM',
    distanceKm: 9.8,
    tags: ['Quiet Coastline', 'Reflection'],
    reviews: [
      PlaceReview(
        reviewerName: 'Grace M.',
        rating: 4.6,
        comment:
            'Almost untouched and very serene. Great for clearing your mind.',
        date: DateTime(2026, 7, 22),
      ),
    ],
  ),
  GreenSpace(
    id: 'gs-008',
    name: 'Mayo Bay Park',
    description:
        'A bayside green area with coconut palms and open space for quiet relaxation and contemplation.',
    category: 'Waterfront',
    address: 'Mayo, Mati City, Davao Oriental',
    latitude: 6.9300,
    longitude: 126.2820,
    amenities: ['Palm shade', 'Bay view', 'Open space'],
    noiseLevel: CrowdLevel.low,
    crowdDensity: CrowdLevel.moderate,
    calmFactor: CrowdLevel.high,
    imageUrl: 'assets/images/pujada_bay.jpg',
    destressTag: 'BAYSIDE RECHARGE',
    distanceKm: 5.4,
    tags: ['Bay Breeze', 'Palm Trees'],
    reviews: [
      PlaceReview(
        reviewerName: 'Maria J.',
        rating: 4.5,
        comment:
            'The morning hours are perfect for my meditation sessions. Not too crowded.',
        date: DateTime(2026, 7, 15),
      ),
      PlaceReview(
        reviewerName: 'Ryan A.',
        rating: 4.5,
        comment:
            'Great for walks. Shaded and benches to sit and enjoy the greenery.',
        date: DateTime(2026, 7, 28),
      ),
    ],
  ),
];

final seedSuggestedUsers = <AppUser>[
  AppUser(
    id: 'u-1',
    name: 'Rain Heart',
    handle: '@rainheart',
    email: 'rain@example.com',
    age: 24,
    createdAt: DateTime(2026, 1, 15),
    followersCount: '18.1k',
    isVerified: true,
  ),
  AppUser(
    id: 'u-2',
    name: 'Paul Filipe',
    handle: '@paulfilipe',
    email: 'paul@example.com',
    age: 27,
    createdAt: DateTime(2026, 2, 20),
    followersCount: '203k',
    isVerified: true,
  ),
  AppUser(
    id: 'u-3',
    name: 'Elena Ramos',
    handle: '@elenaramos',
    email: 'elena@example.com',
    age: 22,
    createdAt: DateTime(2026, 3, 10),
    followersCount: '12.4k',
    isVerified: false,
  ),
];

final seedStories = <Story>[
  const Story(
    id: 's-0',
    userId: 'current-user',
    userName: 'Your Story',
    userAvatar: '',
    isUser: true,
    hasUnseen: false,
  ),
  const Story(
    id: 's-1',
    userId: 'u-1',
    userName: 'Rain Heart',
    userAvatar: '',
    hasUnseen: true,
  ),
  const Story(
    id: 's-2',
    userId: 'u-2',
    userName: 'Paul Filipe',
    userAvatar: '',
    hasUnseen: true,
  ),
  const Story(
    id: 's-3',
    userId: 'u-3',
    userName: 'Elena',
    userAvatar: '',
    hasUnseen: true,
  ),
  const Story(
    id: 's-4',
    userId: 'u-4',
    userName: 'Marcus',
    userAvatar: '',
    hasUnseen: false,
  ),
];

final seedCommunityPosts = <CommunityPost>[
  CommunityPost(
    id: 'post-1',
    userId: 'u-1',
    userName: 'Rain Heart',
    userAvatar: '',
    locationName: 'Dahican Beach',
    locationAddress: 'Roxas Boulevard, Dahican, Mati City, 8200 Davao Oriental',
    rating: 4.5,
    imageUrl: 'assets/images/dahican_beach.jpg',
    caption: 'Early morning meditation by the shoreline. The sound of waves instantly grounded my busy mind 🌊🍃',
    likedByPreview: ['juan', 'Mike', '5sda'],
    likesCount: 134500,
    commentsCount: 100940,
    sharesCount: 12400,
    isLiked: false,
    isFollowing: true,
    createdAt: DateTime(2026, 8, 20, 7, 30),
  ),
  CommunityPost(
    id: 'post-2',
    userId: 'u-2',
    userName: 'Paul Filipe',
    userAvatar: '',
    locationName: 'Guang-guang Mangrove Park',
    locationAddress: 'Dahican, Mati City, 8200 Davao Oriental',
    rating: 4.8,
    imageUrl: 'assets/images/guang_guang_mangrove.jpg',
    caption: 'Completed 15 minutes of box breathing under the mangrove canopy. Stress reduction score: +6! 🌿✨',
    likedByPreview: ['Arlene', 'Maria', 'Ryan'],
    likesCount: 89200,
    commentsCount: 4120,
    sharesCount: 3800,
    isLiked: true,
    isFollowing: true,
    createdAt: DateTime(2026, 8, 19, 16, 15),
  ),
  CommunityPost(
    id: 'post-3',
    userId: 'u-3',
    userName: 'Elena Ramos',
    userAvatar: '',
    locationName: 'Mati City Freedom Park',
    locationAddress: 'City Center, Mati City, 8200 Davao Oriental',
    rating: 4.2,
    imageUrl: 'assets/images/freedom_park.jpg',
    caption: 'Twilight walk after a long workday. Fresh breeze and glowing lanterns cleared my tension completely.',
    likedByPreview: ['Kim', 'Leo', 'Angelo'],
    likesCount: 45300,
    commentsCount: 1820,
    sharesCount: 940,
    isLiked: false,
    isFollowing: false,
    createdAt: DateTime(2026, 8, 18, 19, 00),
  ),
];

final seedNotifications = <NotificationItem>[
  NotificationItem(
    id: 'notif-1',
    title: '🌿 Time for your Mindful Walk!',
    description: 'The weather in Mati City is partly cloudy (28°C) — ideal conditions for Guang-guang Mangrove Park.',
    category: NotificationCategory.reminder,
    timestamp: DateTime.now().subtract(const Duration(minutes: 25)),
    isRead: false,
    actionRoute: '/weather',
  ),
  NotificationItem(
    id: 'notif-2',
    title: '🔥 5-Day Streak Active!',
    description: 'You\'ve logged nature wellness visits 5 days in a row! Keep going to earn your Mindfulness Badge.',
    category: NotificationCategory.reminder,
    timestamp: DateTime.now().subtract(const Duration(hours: 3)),
    isRead: false,
    actionRoute: '/dashboard',
  ),
  NotificationItem(
    id: 'notif-3',
    title: '❤️ Rain Heart liked your visit post',
    description: 'Rain Heart and 42 others liked your recent reflection at Dahican Beach.',
    category: NotificationCategory.community,
    timestamp: DateTime.now().subtract(const Duration(hours: 6)),
    isRead: true,
    actionRoute: '/community',
  ),
  NotificationItem(
    id: 'notif-4',
    title: '☀️ Perfect Sunset Window',
    description: 'Calm winds and clear skies expected at Pujada Bay around 5:30 PM. Great for a 10-min reflection.',
    category: NotificationCategory.weather,
    timestamp: DateTime.now().subtract(const Duration(days: 1)),
    isRead: true,
    actionRoute: '/weather',
  ),
];