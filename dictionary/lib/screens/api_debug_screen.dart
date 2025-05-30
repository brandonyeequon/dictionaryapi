import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../services/jisho_api_service.dart';
import '../config/api_config.dart';

/// Debug screen for API configuration and connectivity testing
/// 
/// This screen provides detailed information about the current API configuration,
/// platform detection, and allows testing of API connectivity. Useful for
/// troubleshooting CORS and network issues.
class ApiDebugScreen extends StatefulWidget {
  const ApiDebugScreen({super.key});

  @override
  State<ApiDebugScreen> createState() => _ApiDebugScreenState();
}

class _ApiDebugScreenState extends State<ApiDebugScreen> {
  Map<String, dynamic>? _connectivityResult;
  bool _isTestingConnectivity = false;
  String _testKeyword = 'house';

  @override
  void initState() {
    super.initState();
    _testConnectivity();
  }

  Future<void> _testConnectivity() async {
    setState(() => _isTestingConnectivity = true);
    
    try {
      final result = await JishoApiService.testConnectivity();
      setState(() {
        _connectivityResult = result;
        _isTestingConnectivity = false;
      });
    } catch (e) {
      setState(() {
        _connectivityResult = {
          'status': 'error',
          'error': e.toString(),
          'timestamp': DateTime.now().toIso8601String(),
        };
        _isTestingConnectivity = false;
      });
    }
  }

  Future<void> _testCustomKeyword() async {
    if (_testKeyword.trim().isEmpty) return;
    
    setState(() => _isTestingConnectivity = true);
    
    try {
      final startTime = DateTime.now();
      final response = await JishoApiService.searchWords(_testKeyword);
      final endTime = DateTime.now();
      final duration = endTime.difference(startTime);
      
      setState(() {
        _connectivityResult = {
          'status': 'success',
          'keyword': _testKeyword,
          'responseTime': duration.inMilliseconds,
          'timestamp': endTime.toIso8601String(),
          'resultsCount': response?.data.length ?? 0,
          'hasResults': response?.data.isNotEmpty ?? false,
          'apiInfo': JishoApiService.getApiInfo(),
        };
        _isTestingConnectivity = false;
      });
    } catch (e) {
      final endTime = DateTime.now();
      setState(() {
        _connectivityResult = {
          'status': 'error',
          'keyword': _testKeyword,
          'error': e.toString(),
          'timestamp': endTime.toIso8601String(),
          'apiInfo': JishoApiService.getApiInfo(),
        };
        _isTestingConnectivity = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('API Debug'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
        actions: [
          IconButton(
            onPressed: _testConnectivity,
            icon: const Icon(Icons.refresh),
            tooltip: 'Refresh connectivity test',
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildApiConfigSection(),
            const SizedBox(height: 24),
            _buildConnectivityTestSection(),
            const SizedBox(height: 24),
            _buildCustomTestSection(),
            const SizedBox(height: 24),
            _buildTroubleshootingSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildApiConfigSection() {
    final apiInfo = JishoApiService.getApiInfo();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.settings, color: Colors.blue),
                const SizedBox(width: 8),
                const Text(
                  'API Configuration',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => _copyToClipboard(apiInfo.toString()),
                  icon: const Icon(Icons.copy, size: 16),
                  tooltip: 'Copy configuration',
                ),
              ],
            ),
            const SizedBox(height: 12),
            _buildInfoRow('Current URL', apiInfo['currentUrl']),
            _buildInfoRow('Is Web', apiInfo['isWeb'].toString()),
            _buildInfoRow('Platform', apiInfo['platform']),
          ],
        ),
      ),
    );
  }

  Widget _buildConnectivityTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  _getConnectivityIcon(),
                  color: _getConnectivityColor(),
                ),
                const SizedBox(width: 8),
                const Text(
                  'Connectivity Test',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                if (_isTestingConnectivity)
                  const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                else
                  IconButton(
                    onPressed: _testConnectivity,
                    icon: const Icon(Icons.play_arrow, size: 16),
                    tooltip: 'Run test',
                  ),
              ],
            ),
            const SizedBox(height: 12),
            if (_connectivityResult != null) ...[
              _buildInfoRow('Status', _connectivityResult!['status']),
              if (_connectivityResult!['responseTime'] != null)
                _buildInfoRow('Response Time', 
                    '${_connectivityResult!['responseTime']}ms'),
              if (_connectivityResult!['error'] != null)
                _buildInfoRow('Error', _connectivityResult!['error']),
              if (_connectivityResult!['hasResults'] != null)
                _buildInfoRow('Has Results', 
                    _connectivityResult!['hasResults'].toString()),
              _buildInfoRow('Timestamp', _connectivityResult!['timestamp']),
            ] else ...[
              const Text('Run connectivity test to see results'),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildCustomTestSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.search, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Custom Search Test',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: TextField(
                    onChanged: (value) => _testKeyword = value,
                    decoration: const InputDecoration(
                      hintText: 'Enter keyword to test',
                      border: OutlineInputBorder(),
                    ),
                    controller: TextEditingController(text: _testKeyword),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _isTestingConnectivity ? null : _testCustomKeyword,
                  child: const Text('Test'),
                ),
              ],
            ),
            if (_connectivityResult?['keyword'] != null) ...[
              const SizedBox(height: 12),
              _buildInfoRow('Last Tested', _connectivityResult!['keyword']),
              if (_connectivityResult!['resultsCount'] != null)
                _buildInfoRow('Results Count', 
                    _connectivityResult!['resultsCount'].toString()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTroubleshootingSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.help_outline, color: Colors.orange),
                SizedBox(width: 8),
                Text(
                  'Troubleshooting',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Text('Common Issues:'),
            const SizedBox(height: 8),
            _buildTroubleshootingItem(
              'CORS Errors on Web',
              'Ensure proxy is deployed and URL is correct',
            ),
            _buildTroubleshootingItem(
              'Network Timeouts',
              'Check internet connection and proxy server status',
            ),
            _buildTroubleshootingItem(
              'No Results',
              'Try different keywords or check Jisho.org status',
            ),
            const SizedBox(height: 12),
            if (ApiConfig.isWeb) ...[
              const Text('Web Platform Recommendations:'),
              const SizedBox(height: 8),
              _buildTroubleshootingItem(
                'Development',
                'Ensure proxy is running locally on port 3000',
              ),
              _buildTroubleshootingItem(
                'Production',
                'Verify proxy is deployed on Vercel/hosting platform',
              ),
            ] else ...[
              const Text('Mobile/Desktop Platform:'),
              const SizedBox(height: 8),
              _buildTroubleshootingItem(
                'Direct API',
                'No proxy needed - connects directly to Jisho.org',
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              '$label:',
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            child: SelectableText(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTroubleshootingItem(String issue, String solution) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: DefaultTextStyle.of(context).style,
                children: [
                  TextSpan(
                    text: '$issue: ',
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                  TextSpan(text: solution),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  IconData _getConnectivityIcon() {
    if (_isTestingConnectivity) return Icons.hourglass_empty;
    if (_connectivityResult == null) return Icons.help_outline;
    
    final status = _connectivityResult!['status'];
    return status == 'success' ? Icons.check_circle : Icons.error;
  }

  Color _getConnectivityColor() {
    if (_isTestingConnectivity) return Colors.orange;
    if (_connectivityResult == null) return Colors.grey;
    
    final status = _connectivityResult!['status'];
    return status == 'success' ? Colors.green : Colors.red;
  }

  void _copyToClipboard(String text) {
    Clipboard.setData(ClipboardData(text: text));
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Copied to clipboard')),
    );
  }
}