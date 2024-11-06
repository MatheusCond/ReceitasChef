import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class RecipeResponse {
  final String title;
  final int servings;
  final String prepTime;
  final List<String> ingredients;
  final List<String> instructions;
  final List<String> tips;
  final NutritionInfo nutritionInfo;

  RecipeResponse({
    required this.title,
    required this.servings,
    required this.prepTime,
    required this.ingredients,
    required this.instructions,
    required this.tips,
    required this.nutritionInfo,
  });

  factory RecipeResponse.fromJson(Map<String, dynamic> json) {
    return RecipeResponse(
      title: json['title'] as String,
      servings: json['servings'] as int,
      prepTime: json['prepTime'] as String,
      ingredients: List<String>.from(json['ingredients']),
      instructions: List<String>.from(json['instructions']),
      tips: List<String>.from(json['tips']),
      nutritionInfo: NutritionInfo.fromJson(json['nutritionInfo']),
    );
  }
}

class NutritionInfo {
  final String calories;
  final String protein;
  final String carbs;
  final String fat;

  NutritionInfo({
    required this.calories,
    required this.protein,
    required this.carbs,
    required this.fat,
  });

  factory NutritionInfo.fromJson(Map<String, dynamic> json) {
    return NutritionInfo(
      calories: json['calories'] as String,
      protein: json['protein'] as String,
      carbs: json['carbs'] as String,
      fat: json['fat'] as String,
    );
  }
}

class GeminiService {
  static const String _baseUrl =
      'https://generativelanguage.googleapis.com/v1/models';
  static const String _model = 'gemini-1.5-pro';
  static const String _apiKey = 'AIzaSyBru8HxXQB9_XPlW5cd81no4WQHvqBfnsg';

  void _log(String message) {
    if (kDebugMode) {
      print('GeminiService: $message');
    }
  }

  Future<RecipeResponse> generateRecipe({
    String? title,
    XFile? imageFile,
    required int servings,
  }) async {
    try {
      _log('Iniciando geração da receita');

      if (title == null && imageFile == null) {
        throw Exception('É necessário fornecer uma foto ou um título');
      }

      String? base64Image;
      if (imageFile != null) {
        final List<int> imageBytes = await imageFile.readAsBytes();
        base64Image = base64Encode(imageBytes);
        _log(
            'Imagem convertida com sucesso. Tamanho: ${base64Image.length} caracteres');

        if (base64Image.length > 20000000) {
          throw Exception(
              'Imagem muito grande. Por favor, use uma imagem menor.');
        }
      }

      final prompt = '''
Você é um chef profissional especializado em criar receitas. 
${imageFile != null ? 'Analise esta imagem do prato' : ''}
${title != null ? 'O nome do prato é: $title' : imageFile != null ? 'Identifique o prato na imagem' : ''}
${title != null && imageFile != null ? '\nConfirme se a imagem corresponde ao título fornecido.' : ''}

Crie uma receita detalhada em português para $servings pessoas.

Retorne APENAS o JSON sem nenhum texto adicional, seguindo exatamente esta estrutura:
{
  "title": "${title ?? 'Nome do prato identificado'}",
  "servings": $servings,
  "prepTime": "tempo de preparo, diga se é em horas ou minutos",
  "ingredients": [
    "quantidade + ingrediente 1",
    "quantidade + ingrediente 2"
  ],
  "instructions": [
    "passo detalhado 1",
    "passo detalhado 2"
  ],
  "tips": [
    "dica de preparo 1",
    "dica de apresentação 1"
  ],
  "nutritionInfo": {
    "calories": "kcal por porção",
    "protein": "g",
    "carbs": "g",
    "fat": "g"
  }
}

Certifique-se de que:
1. As quantidades dos ingredientes sejam proporcionais ao número de pessoas
2. As instruções sejam claras e detalhadas
3. Inclua dicas práticas de preparo e apresentação
4. Forneça informações nutricionais aproximadas
''';

      final parts = <Map<String, dynamic>>[
        {'text': prompt}
      ];

      if (imageFile != null) {
        parts.add({
          'inline_data': {'mime_type': 'image/jpeg', 'data': base64Image}
        });
      }

      final payload = {
        'contents': [
          {'parts': parts}
        ],
        'generation_config': {
          'temperature': 0.7,
          'top_p': 0.8,
          'top_k': 40,
          'max_output_tokens': 2048,
        }
      };

      _log('Enviando requisição para API Gemini');

      final uri = Uri.parse('$_baseUrl/$_model:generateContent?key=$_apiKey');
      final response = await http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(payload),
      );

      _log('Status da resposta: ${response.statusCode}');

      if (response.statusCode != 200) {
        _log('Erro na resposta: ${response.body}');
        throw Exception(
            'Erro ao gerar receita. Código: ${response.statusCode}');
      }

      final responseData = json.decode(response.body);

      if (!_isValidResponse(responseData)) {
        _log('Resposta inválida: $responseData');
        throw Exception('Formato de resposta inválido da API');
      }

      final generatedText =
          responseData['candidates'][0]['content']['parts'][0]['text'];
      final recipe = _parseRecipeJson(generatedText);

      _validateAndAdjustRecipe(recipe, servings);

      _log('Receita gerada com sucesso');
      return RecipeResponse.fromJson(recipe);
    } catch (e) {
      _log('Erro durante a geração da receita: $e');
      throw Exception('Falha ao gerar receita: $e');
    }
  }

  bool _isValidResponse(Map<String, dynamic> response) {
    try {
      return response['candidates'] != null &&
          response['candidates'].isNotEmpty &&
          response['candidates'][0]['content'] != null &&
          response['candidates'][0]['content']['parts'] != null &&
          response['candidates'][0]['content']['parts'].isNotEmpty;
    } catch (e) {
      _log('Erro ao validar resposta: $e');
      return false;
    }
  }

  Map<String, dynamic> _parseRecipeJson(String text) {
    try {
      final jsonMatch = RegExp(r'{[\s\S]*}').firstMatch(text);
      if (jsonMatch == null) {
        throw Exception('JSON não encontrado na resposta');
      }

      final jsonStr = jsonMatch.group(0) ?? '{}';
      return json.decode(jsonStr);
    } catch (e) {
      _log('Erro ao fazer parse do JSON: $e');
      throw Exception('Erro ao processar a receita: $e');
    }
  }

  void _validateAndAdjustRecipe(Map<String, dynamic> recipe, int servings) {
    final requiredFields = ['title', 'ingredients', 'instructions'];
    for (final field in requiredFields) {
      if (!recipe.containsKey(field) || recipe[field] == null) {
        throw Exception('Campo obrigatório ausente: $field');
      }
    }

    if (recipe['ingredients'] is! List || recipe['instructions'] is! List) {
      throw Exception('Formato inválido para ingredientes ou instruções');
    }

    if ((recipe['ingredients'] as List).isEmpty ||
        (recipe['instructions'] as List).isEmpty) {
      throw Exception('Ingredientes ou instruções não podem estar vazios');
    }

    recipe['prepTime'] = recipe['prepTime'] ?? '30 minutos';
    recipe['tips'] = recipe['tips'] ?? [];
    recipe['nutritionInfo'] = recipe['nutritionInfo'] ??
        {
          'calories': 'Não disponível',
          'protein': 'Não disponível',
          'carbs': 'Não disponível',
          'fat': 'Não disponível'
        };
    recipe['servings'] = servings;

    recipe['title'] = _capitalizeFirstLetter(recipe['title'] as String);
    recipe['ingredients'] = (recipe['ingredients'] as List)
        .map((item) => _capitalizeFirstLetter(item.toString()))
        .toList();
    recipe['instructions'] = (recipe['instructions'] as List)
        .map((item) => _capitalizeFirstLetter(item.toString()))
        .toList();
    recipe['tips'] = (recipe['tips'] as List)
        .map((item) => _capitalizeFirstLetter(item.toString()))
        .toList();
  }

  String _capitalizeFirstLetter(String text) {
    if (text.isEmpty) return text;
    return text[0].toUpperCase() + text.substring(1);
  }
}
