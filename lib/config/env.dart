/// Environment configuration for dev/prod switching.
enum Env { dev, prod }

class EnvConfig {
  EnvConfig._();

  static Env _currentEnv = Env.dev;

  static Env get current => _currentEnv;

  static void setEnv(Env env) {
    _currentEnv = env;
  }

  static String get backendUrl {
    switch (_currentEnv) {
      case Env.dev:
        return 'ws://10.0.2.2:8080'; // Android emulator → host
      case Env.prod:
        return 'wss://medlens-backend-XXXXX.run.app'; // Cloud Run URL
    }
  }

  static bool get isDebug => _currentEnv == Env.dev;
}
