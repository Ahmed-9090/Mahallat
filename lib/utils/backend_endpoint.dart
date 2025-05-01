class BackendEndpoint {
 static const addUserData = 'users';
 static const getUserData = 'users';
 static const images = 'images';
 static const usersCollection = 'users';

 static const String basePath = 'stores';

 // Document path for a specific store
 static String getStore(String storeId) => '$basePath/$storeId';

 // Collection path for creating stores (same as base)
 static const String createStore = basePath;

 // Document path for updating
 static String updateStore(String storeId) => getStore(storeId);

 // Document path for deleting
 static String deleteStore(String storeId) => getStore(storeId);

 // Query path for category (still uses base collection)
 static String getByCategory(String category) => basePath;

 // Query path for type (still uses base collection)
 static const String getByType = basePath;
 static const String menClothes = 'MenClothes';
 static const String womenClothes = 'WomenClothes';
 static const String kidsClothes = 'KidsClothes';
 static const String menShoes = 'MenShoes';
 static const String womenShoes = 'WomenShoes';
 static const String kidsShoes = 'KidsShoes';
 static const String healthAndCare = 'HealthAndCare';
 static const String bags = 'Bags';


}