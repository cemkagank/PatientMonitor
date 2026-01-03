import { SERVER_URL } from "@/ip";
import { MaterialIcons } from "@expo/vector-icons";
import { useEffect, useState } from "react";
import { ActivityIndicator, Animated, StyleSheet, Text, View } from "react-native";

interface SensorData {
  posture: string;
  pressure: number;
  battery: number;
}

export default function App() {
  const [data, setData] = useState<SensorData | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [pulseAnim] = useState(new Animated.Value(1));

  useEffect(() => {
    const interval = setInterval(() => {
      fetch(`${SERVER_URL}/data`)
        .then(res => res.json())
        .then(json => {
          setData(json);
          setError(null);
        })
        .catch(err => {
          setError("Cannot connect to server");
        });
    }, 500);

    return () => clearInterval(interval);
  }, []);

  useEffect(() => {
    if (data) {
      Animated.loop(
        Animated.sequence([
          Animated.timing(pulseAnim, {
            toValue: 1.05,
            duration: 1000,
            useNativeDriver: true,
          }),
          Animated.timing(pulseAnim, {
            toValue: 1,
            duration: 1000,
            useNativeDriver: true,
          }),
        ])
      ).start();
    }
  }, [data]);

  const translatePosture = (posture: string) => {
    const lowerPosture = posture.toLowerCase();
    if (lowerPosture.includes("tehlikeli") || lowerPosture.includes("dangerous")) {
      return "Dangerous";
    }
    if (lowerPosture.includes("yat") || lowerPosture.includes("lie") || lowerPosture.includes("lying")) {
      return "Lying";
    }
    if (lowerPosture.includes("otur") || lowerPosture.includes("sit") || lowerPosture.includes("sitting")) {
      return "Sitting";
    }
    if (lowerPosture.includes("ayak") || lowerPosture.includes("stand") || lowerPosture.includes("standing")) {
      return "Standing";
    }
    return posture; // Fallback to original if not recognized
  };

  const getPostureIcon = (posture: string) => {
    const lowerPosture = posture.toLowerCase();
    if (lowerPosture.includes("yat") || lowerPosture.includes("lie")) return "bed";
    if (lowerPosture.includes("otur") || lowerPosture.includes("sit")) return "chair";
    if (lowerPosture.includes("ayak") || lowerPosture.includes("stand")) return "directions-walk";
    return "accessibility-new";
  };

  const getBatteryColor = (voltage: number) => {
    if (voltage >= 3.7) return "#10b981"; // green
    if (voltage >= 3.3) return "#f59e0b"; // yellow
    return "#ef4444"; // red
  };

  const getPressureColor = (pressure: number) => {
    if (pressure > 30) return "#ef4444"; // red - high pressure
    return "#10b981"; // green - normal
  };

  const getPostureColor = (posture: string) => {
    // Pozisyon değerine göre tehlikeli durum kontrolü
    const lowerPosture = posture.toLowerCase();
    // Tehlikeli pozisyonlar: "yat", "lie", "tehlikeli", "dangerous" gibi kelimeler içeriyorsa
    if (lowerPosture.includes("yat") || lowerPosture.includes("lie") || 
        lowerPosture.includes("tehlikeli") || lowerPosture.includes("dangerous")) {
      return "#ef4444"; // red - dangerous position
    }
    return "#60a5fa"; // blue - normal
  };

  const isDangerousPosture = (posture: string) => {
    const lowerPosture = posture.toLowerCase();
    return lowerPosture.includes("yat") || lowerPosture.includes("lie") || 
           lowerPosture.includes("tehlikeli") || lowerPosture.includes("dangerous");
  };

  return (
    <View style={styles.container}>
      <View style={styles.header}>
        <MaterialIcons name="monitor-heart" size={32} color="#60a5fa" />
        <Text style={styles.title}>Patient Monitor</Text>
        <Text style={styles.subtitle}>Real-time Sensor Data</Text>
      </View>

      {error && (
        <View style={styles.errorCard}>
          <MaterialIcons name="error-outline" size={24} color="#ef4444" />
          <Text style={styles.errorText}>{error}</Text>
        </View>
      )}

      {data ? (
        <Animated.View style={[styles.dataContainer, { transform: [{ scale: pulseAnim }] }]}>
          <View style={styles.dataCard}>
            <View style={[styles.iconContainer, { backgroundColor: isDangerousPosture(data.posture) ? "rgba(239, 68, 68, 0.2)" : "rgba(96, 165, 250, 0.2)" }]}>
              <MaterialIcons name={getPostureIcon(data.posture)} size={32} color={getPostureColor(data.posture)} />
            </View>
            <View style={styles.dataContent}>
              <Text style={styles.dataLabel}>Posture</Text>
              <Text style={[styles.dataValue, { color: getPostureColor(data.posture) }]}>
                {translatePosture(data.posture)}
              </Text>
            </View>
          </View>

          <View style={styles.dataCard}>
            <View style={[styles.iconContainer, { backgroundColor: data.pressure > 30 ? "rgba(239, 68, 68, 0.2)" : "rgba(16, 185, 129, 0.2)" }]}>
              <MaterialIcons name="speed" size={32} color={getPressureColor(data.pressure)} />
            </View>
            <View style={styles.dataContent}>
              <Text style={styles.dataLabel}>Pressure</Text>
              <Text style={[styles.dataValue, { color: getPressureColor(data.pressure) }]}>
                {data.pressure} <Text style={styles.unit}>mmHg</Text>
              </Text>
            </View>
          </View>

          <View style={styles.dataCard}>
            <View style={[styles.iconContainer, { backgroundColor: "rgba(16, 185, 129, 0.2)" }]}>
              <MaterialIcons name="battery-charging-full" size={32} color={getBatteryColor(data.battery)} />
            </View>
            <View style={styles.dataContent}>
              <Text style={styles.dataLabel}>Battery Level</Text>
              <Text style={[styles.dataValue, { color: getBatteryColor(data.battery) }]}>
                {data.battery} <Text style={styles.unit}>V</Text>
              </Text>
            </View>
          </View>
        </Animated.View>
      ) : (
        <View style={styles.loadingContainer}>
          <ActivityIndicator size="large" color="#60a5fa" />
          <Text style={styles.loadingText}>Waiting for data...</Text>
        </View>
      )}

      <View style={styles.statusBar}>
        <View style={[styles.statusDot, { backgroundColor: data ? "#10b981" : "#6b7280" }]} />
        <Text style={styles.statusText}>
          {data ? "Connected" : "Connecting..."}
        </Text>
      </View>
    </View>
  );
}

const styles = StyleSheet.create({
  container: {
    flex: 1,
    backgroundColor: "#0f172a",
    paddingTop: 60,
    paddingHorizontal: 20,
    paddingBottom: 40,
  },
  header: {
    alignItems: "center",
    marginBottom: 40,
  },
  title: {
    color: "#ffffff",
    fontSize: 28,
    fontWeight: "700",
    marginTop: 12,
    letterSpacing: 0.5,
  },
  subtitle: {
    color: "#94a3b8",
    fontSize: 14,
    marginTop: 4,
    fontWeight: "500",
  },
  errorCard: {
    flexDirection: "row",
    alignItems: "center",
    backgroundColor: "rgba(239, 68, 68, 0.15)",
    padding: 16,
    borderRadius: 12,
    marginBottom: 20,
    borderWidth: 1,
    borderColor: "rgba(239, 68, 68, 0.3)",
  },
  errorText: {
    color: "#ef4444",
    fontSize: 16,
    marginLeft: 12,
    fontWeight: "500",
  },
  dataContainer: {
    gap: 16,
    flex: 1,
  },
  dataCard: {
    flexDirection: "row",
    backgroundColor: "#1e293b",
    padding: 20,
    borderRadius: 16,
    alignItems: "center",
    shadowColor: "#000",
    shadowOffset: { width: 0, height: 4 },
    shadowOpacity: 0.3,
    shadowRadius: 8,
    elevation: 8,
    borderWidth: 1,
    borderColor: "rgba(148, 163, 184, 0.1)",
  },
  iconContainer: {
    width: 64,
    height: 64,
    borderRadius: 16,
    backgroundColor: "rgba(96, 165, 250, 0.2)",
    alignItems: "center",
    justifyContent: "center",
    marginRight: 16,
  },
  dataContent: {
    flex: 1,
  },
  dataLabel: {
    color: "#94a3b8",
    fontSize: 14,
    fontWeight: "500",
    marginBottom: 4,
    textTransform: "uppercase",
    letterSpacing: 1,
  },
  dataValue: {
    color: "#ffffff",
    fontSize: 24,
    fontWeight: "700",
  },
  unit: {
    fontSize: 16,
    fontWeight: "400",
    color: "#94a3b8",
  },
  loadingContainer: {
    flex: 1,
    alignItems: "center",
    justifyContent: "center",
  },
  loadingText: {
    color: "#94a3b8",
    fontSize: 16,
    marginTop: 16,
    fontWeight: "500",
  },
  statusBar: {
    flexDirection: "row",
    alignItems: "center",
    justifyContent: "center",
    marginTop: 20,
    paddingVertical: 12,
  },
  statusDot: {
    width: 8,
    height: 8,
    borderRadius: 4,
    marginRight: 8,
  },
  statusText: {
    color: "#94a3b8",
    fontSize: 14,
    fontWeight: "500",
  },
});