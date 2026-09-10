import 'habit_category.dart';

/// A starting point offered when creating a habit - not a distinct data
/// model, just pre-filled values for the Add Habit form.
class HabitTemplate {
  const HabitTemplate({
    required this.name,
    required this.emoji,
    required this.category,
    this.note,
  });

  final String name;
  final String emoji;
  final HabitCategory category;
  final String? note;
}

const List<HabitTemplate> generalHabitTemplates = [
  HabitTemplate(name: 'Beber agua', emoji: '💧', category: HabitCategory.general),
  HabitTemplate(name: 'Hacer ejercicio', emoji: '🏃', category: HabitCategory.general),
  HabitTemplate(name: 'Leer 10 páginas', emoji: '📖', category: HabitCategory.general),
  HabitTemplate(name: 'Dormir 7+ horas', emoji: '😴', category: HabitCategory.general),
  HabitTemplate(name: 'Meditar', emoji: '🧘', category: HabitCategory.general),
  HabitTemplate(name: 'Sin azúcar', emoji: '🍬', category: HabitCategory.general),
  HabitTemplate(name: 'Ordenar el espacio de trabajo', emoji: '🧹', category: HabitCategory.general),
  HabitTemplate(name: 'Aprender algo nuevo', emoji: '💡', category: HabitCategory.general),
];

const List<HabitTemplate> tradingHabitTemplates = [
  HabitTemplate(
    name: 'Seguí mi plan de trading',
    emoji: '📋',
    category: HabitCategory.trading,
    note: '¿Cada operación de hoy siguió un setup y una regla predefinidos, y no un impulso?',
  ),
  HabitTemplate(
    name: 'Respeté el riesgo máximo por operación',
    emoji: '🛡️',
    category: HabitCategory.trading,
    note: 'Te mantuviste dentro del riesgo configurado por operación en cada posición.',
  ),
  HabitTemplate(
    name: 'Sin revenge trading',
    emoji: '🚫',
    category: HabitCategory.trading,
    note: 'No intentaste "recuperar" una pérdida con una operación no planificada.',
  ),
  HabitTemplate(
    name: 'Registré cada operación en el diario',
    emoji: '📝',
    category: HabitCategory.trading,
  ),
  HabitTemplate(
    name: 'Checklist antes del mercado',
    emoji: '✅',
    category: HabitCategory.trading,
    note: 'Revisaste el sesgo, niveles clave y noticias antes de abrir la sesión.',
  ),
  HabitTemplate(
    name: 'Me detuve al llegar al límite de pérdida diaria',
    emoji: '🛑',
    category: HabitCategory.trading,
  ),
  HabitTemplate(
    name: 'Revisé las operaciones de hoy',
    emoji: '🔍',
    category: HabitCategory.trading,
  ),
];
