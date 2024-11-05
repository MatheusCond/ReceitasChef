import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'login_screen.dart';
import 'dart:io';

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
    return Image.file(
      File(imageFile.path),
      width: width,
      height: height,
      fit: fit,
    );
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

  // Simula a ação de selecionar a imagem (sem backend)
  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
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
                      onPressed: _isLoading
                          ? null
                          : () {
                              // Simula a ação de gerar receita
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text('Receita gerada com sucesso!'),
                                  backgroundColor:
                                      Color.fromARGB(255, 136, 10, 1),
                                ),
                              );
                            },
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
