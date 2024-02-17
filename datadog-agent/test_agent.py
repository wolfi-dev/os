import unittest
import subprocess

class TestDatadogAgentHelpMessage(unittest.TestCase):
    def test_help_message(self):
        # Define the command to test
        command = '/opt/datadog-agent/bin/agent/agent --help'
        
        # Execute the command
        result = subprocess.run(command, shell=True, text=True, capture_output=True)
        
        # Check if the command executed successfully
        self.assertEqual(result.returncode, 0, "Command failed to execute")

        # Validate the presence of expected text in the help message
        expected_text = 'Usage:'
        self.assertIn(expected_text, result.stdout, "Help message does not contain expected text")

if __name__ == '__main__':
    unittest.main()
