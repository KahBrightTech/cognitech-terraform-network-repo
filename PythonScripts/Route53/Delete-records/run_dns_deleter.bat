@echo off
echo.
echo =================================================
echo    DNS Record Deleter - Bulk Delete Tool
echo =================================================
echo.
echo Starting DNS Record Deleter with Streamlit UI...
echo.

cd /d "%~dp0"

REM Check if Python is installed
python --version >nul 2>&1
if errorlevel 1 (
    echo ERROR: Python is not installed or not in PATH
    echo Please install Python and try again
    pause
    exit /b 1
)

REM Check if required packages are installed
echo Checking dependencies...
python -c "import streamlit, boto3, pandas, openpyxl" >nul 2>&1
if errorlevel 1 (
    echo Installing required packages...
    pip install --user streamlit boto3 pandas openpyxl
    if errorlevel 1 (
        echo ERROR: Failed to install required packages
        pause
        exit /b 1
    )
)

echo.
echo Dependencies verified successfully!
echo.
echo Starting DNS Record Deleter...
echo Your browser will open automatically.
echo.
echo To stop the application, press Ctrl+C in this window.
echo.

REM Start Streamlit
python -m streamlit run delete_dns_record.py --server.port 8502 --server.headless false

pause
