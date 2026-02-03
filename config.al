{
    "store": {
        "type": "sqlite",
        "dbname": "accessprocessor_db"
    },
    "service": {
        "port": "#js parseInt(process.env.SERVICE_PORT || '8083')"
    },
    "integrations": {
        "host": "#js process.env.INTEG_MANAGER_HOST || 'http://localhost:8000'",
        "username": "#js process.env.INTEG_MANAGER_USER || ''",
        "password": "#js process.env.INTEG_MANAGER_PASSWORD || ''",
        "connections": {
            "servicenow": "accessprocessor/servicenow"
        }
    }
}
