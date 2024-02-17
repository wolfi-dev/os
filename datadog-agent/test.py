import subprocess

def test_help_message():
    # Define the command to test
    command = '/opt/datadog-agent/bin/agent/agent --help'
    
    # Execute the command
    result = subprocess.run(command, shell=True, text=True, capture_output=True)
    
    # Check if the command executed successfully
    assert result.returncode == 0, "Command failed to execute"

    # Validate the presence of expected text in the help message
    expected_text = 'Usage:'
    assert expected_text in result.stdout, "Help message does not contain expected text"

