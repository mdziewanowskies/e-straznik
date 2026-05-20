import 'package:supabase_flutter/supabase_flutter.dart';

String mapErrorToPolish(Object error) {
  if (error is AuthApiException || error is AuthException) {
    final msg = (error as dynamic).message?.toString().toLowerCase() ?? '';
    if (msg.contains('invalid login') ||
        msg.contains('invalid credentials') ||
        msg.contains('invalid_grant')) {
      return 'Nieprawidłowy email lub hasło.';
    }
    if (msg.contains('email not confirmed')) {
      return 'Email nie został potwierdzony. Sprawdź skrzynkę.';
    }
    if (msg.contains('rate limit')) {
      return 'Zbyt wiele prób. Spróbuj ponownie za chwilę.';
    }
    if (msg.contains('network')) {
      return 'Brak połączenia z serwerem.';
    }
    return 'Logowanie nie powiodło się. Spróbuj ponownie.';
  }
  if (error is PostgrestException) {
    if (error.code == 'PGRST301' || error.code == '42501') {
      return 'Brak uprawnień do tych danych.';
    }
    return 'Błąd serwera. Spróbuj ponownie za chwilę.';
  }
  if (error.toString().toLowerCase().contains('socketexception') ||
      error.toString().toLowerCase().contains('failed host lookup')) {
    return 'Brak połączenia z internetem.';
  }
  return 'Coś poszło nie tak. Spróbuj ponownie.';
}
