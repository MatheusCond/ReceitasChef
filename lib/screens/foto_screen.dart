import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'login_screen.dart';
import 'dart:io';
import '../gemini_service.dart';

class CrossPlatformImage extends StatelessWidget {
  final XFile imageFile;
  final double width;
  final double height;
  final BoxFit fit;

  const CrossPlatformImage({
    super.key,
    required this.imageFile,
    this.width = 200,
    this.height = 200,
    this.fit = BoxFit.cover,
  });

  @override
  Widget build(BuildContext context) {
    if (kIsWeb) {
      // Para Web, usamos Image.network com o URL do arquivo
      return Image.network(
        imageFile.path,
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.error),
          );
        },
        loadingBuilder: (context, child, loadingProgress) {
          if (loadingProgress == null) return child;
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Center(
              child: CircularProgressIndicator(),
            ),
          );
        },
      );
    } else {
      // Para mobile, mantemos o Image.file
      return Image.file(
        File(imageFile.path),
        width: width,
        height: height,
        fit: fit,
        errorBuilder: (context, error, stackTrace) {
          return Container(
            width: width,
            height: height,
            color: Colors.grey[300],
            child: const Icon(Icons.error),
          );
        },
      );
    }
  }
}

class FotoScreen extends StatefulWidget {
  const FotoScreen({super.key});

  @override
  State<FotoScreen> createState() => _FotoScreenState();
}

class _FotoScreenState extends State<FotoScreen> {
  XFile? _imagePath;
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _servingsController = TextEditingController();
  String? _errorText;
  bool _isLoading = false;
  final _geminiService = GeminiService();

  // Simula a ação de selecionar a imagem (sem backend)
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
    try {
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );

      if (image != null) {
        setState(() {
          _imagePath = image;
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Erro ao selecionar imagem. Tente novamente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  // Simula a ação de tirar foto (sem backend)
  Future<void> _takePhoto() async {
    final ImagePicker picker = ImagePicker();
    final XFile? image = await picker.pickImage(
      source: ImageSource.camera,
      maxWidth: 1024,
      maxHeight: 1024,
      imageQuality: 85,
    );
    if (image != null) {
      setState(() {
        _imagePath = image;
      });
    }
  }

  // Valida o campo de número de pessoas
  void _validateInput(String value) {
    setState(() {
      if (value.isEmpty) {
        _errorText = 'Por favor, insira o número de pessoas';
      } else {
        try {
          int pessoas = int.parse(value);
          if (pessoas <= 0) {
            _errorText = 'O número deve ser maior que zero';
          } else if (pessoas > 100) {
            _errorText = 'Máximo de 100 pessoas permitido';
          } else {
            _errorText = null;
          }
        } catch (e) {
          _errorText = 'Digite apenas números inteiros';
        }
      }
    });
  }

  Future<void> _generateRecipe() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() {
      _isLoading = true;
    });

    try {
      final servings = int.parse(_servingsController.text);
      final recipe = await _geminiService.generateRecipe(
        imageFile: _imagePath,
        title: _titleController.text.isNotEmpty ? _titleController.text : null,
        servings: servings,
      );

      setState(() {});

      // Mostra o diálogo com a receita
      if (mounted) {
        _showRecipeDialog(recipe);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao gerar receita: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  void _showRecipeDialog(RecipeResponse recipe) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          padding: const EdgeInsets.all(16),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  recipe.title,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text('Tempo de preparo: ${recipe.prepTime}'),
                Text('Porções: ${recipe.servings}'),
                const SizedBox(height: 16),
                const Text(
                  'Ingredientes:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ...recipe.ingredients.map((i) => Text('• $i')),
                const SizedBox(height: 16),
                const Text(
                  'Instruções:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ...recipe.instructions.map((i) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Text('${recipe.instructions.indexOf(i) + 1}. $i'),
                    )),
                const SizedBox(height: 16),
                const Text(
                  'Dicas:',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                ...recipe.tips.map((t) => Text('• $t')),
                const SizedBox(height: 16),
                const Text(
                  'Informações Nutricionais (por porção):',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Text('Calorias: ${recipe.nutritionInfo.calories}'),
                Text('Proteínas: ${recipe.nutritionInfo.protein}'),
                Text('Carboidratos: ${recipe.nutritionInfo.carbs}'),
                Text('Gorduras: ${recipe.nutritionInfo.fat}'),
                const SizedBox(height: 16),
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: const Text('Fechar'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.logout),
          onPressed: () {
            // Redirecionar para a tela de login
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => const LoginScreen()),
            );
          },
        ),
        title: const Text(
          'FOTO DO PRATO',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color.fromARGB(255, 136, 10, 1),
      ),
      body: Container(
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: NetworkImage(
                'https://images.unsplash.com/photo-1502998070258-dc1338445ac2'),
            fit: BoxFit.cover,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Container de fundo semi-transparente para dar destaque ao conteúdo
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black
                          .withOpacity(0.6), // Cor de fundo semi-transparente
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          const Text(
                            'Escolha uma das opções ou ambas:',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 16),
                          if (_imagePath != null)
                            Stack(
                              alignment: Alignment.topRight,
                              children: [
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    boxShadow: [
                                      BoxShadow(
                                        color: Colors.black.withOpacity(0.2),
                                        spreadRadius: 1,
                                        blurRadius: 5,
                                        offset: const Offset(0, 3),
                                      ),
                                    ],
                                  ),
                                  child: ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CrossPlatformImage(
                                      imageFile: _imagePath!,
                                      width: 200,
                                      height: 200,
                                      fit: BoxFit.cover,
                                    ),
                                  ),
                                ),
                                Container(
                                  decoration: const BoxDecoration(
                                    color: Colors.black54,
                                    shape: BoxShape.circle,
                                  ),
                                  child: IconButton(
                                    icon: const Icon(
                                      Icons.close,
                                      color: Colors.white,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _imagePath = null;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            )
                          else
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: [
                                ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _takePhoto,
                                  icon: const Icon(Icons.camera_alt),
                                  label: const Text('Câmera'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 136, 10, 1),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(150, 50),
                                  ),
                                ),
                                ElevatedButton.icon(
                                  onPressed: _isLoading ? null : _pickImage,
                                  icon: const Icon(Icons.photo_library),
                                  label: const Text('Galeria'),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor:
                                        const Color.fromARGB(255, 136, 10, 1),
                                    foregroundColor: Colors.white,
                                    minimumSize: const Size(150, 50),
                                  ),
                                ),
                              ],
                            ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black
                          .withOpacity(0.6), // Fundo semi-transparente
                      borderRadius: BorderRadius.circular(10),
                    ),
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        TextFormField(
                          controller: _titleController,
                          enabled: !_isLoading,
                          decoration: const InputDecoration(
                            labelText: 'Título do Prato (opcional)',
                            border: OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: Icon(Icons.restaurant_menu),
                          ),
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _servingsController,
                          enabled: !_isLoading,
                          keyboardType: TextInputType.number,
                          onChanged: _validateInput,
                          decoration: InputDecoration(
                            labelText: 'Número de Pessoas',
                            errorText: _errorText,
                            border: const OutlineInputBorder(),
                            filled: true,
                            fillColor: Colors.white,
                            prefixIcon: const Icon(Icons.people),
                            suffixText: 'pessoas',
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Por favor, insira o número de pessoas';
                            }
                            if (_errorText != null) {
                              return _errorText;
                            }
                            return null;
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 50,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _generateRecipe,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color.fromARGB(255, 136, 10, 1),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: _isLoading
                          ? const CircularProgressIndicator(
                              valueColor:
                                  AlwaysStoppedAnimation<Color>(Colors.white),
                            )
                          : const Text(
                              'GERAR RECEITA',
                              style: TextStyle(color: Colors.white),
                            ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
