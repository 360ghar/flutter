const baseUrl = API_BASE_URL || 'http://localhost:8000/api/v1';

const response = http.get(baseUrl + '/properties?page=1&limit=1');

if (response.status !== 200) {
  throw new Error('Failed to fetch property list: HTTP ' + response.status);
}

const payload = json(response.body);
const properties = payload.properties || [];
if (!properties.length || !properties[0].id) {
  throw new Error('No property id available for deep-link test');
}

output.propertyId = String(properties[0].id);
