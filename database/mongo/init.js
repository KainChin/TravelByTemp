db = db.getSiblingDB("vietai_ai_logs");

db.createCollection("ai_recommendation_logs");
db.createCollection("weather_snapshots");
db.createCollection("user_interaction_logs");

db.ai_recommendation_logs.createIndex({ userId: 1 });
db.ai_recommendation_logs.createIndex({ scheduleId: 1 });
db.ai_recommendation_logs.createIndex({ createdAt: -1 });
db.ai_recommendation_logs.createIndex({ aiModelUsed: 1 });

db.weather_snapshots.createIndex({ userId: 1 });
db.weather_snapshots.createIndex({ createdAt: -1 });
db.weather_snapshots.createIndex({ locationName: 1 });

db.user_interaction_logs.createIndex({ userId: 1 });
db.user_interaction_logs.createIndex({ eventType: 1 });
db.user_interaction_logs.createIndex({ createdAt: -1 });
