@echo off
cd /d "c:\Users\kbrig\Downloads\GitRepos\cognitech-repos\cognitech-terraform-network-repo\PythonScripts\Route53\Delete-records"
python -m streamlit run delete_dns_record.py --server.port 8502 --server.headless false
