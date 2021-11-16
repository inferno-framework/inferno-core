const apiEndpoint = '/api';

type parameter = {
  name: string;
  value: string;
};

export function getEndpoint(route: string, parameters?: parameter[]): string {
  if (parameters) {
    const parametersString = parameters
      .map((parameter) => `${parameter.name}=${parameter.value}`)
      .join('&');
    return `${apiEndpoint}${route}?${parametersString}`;
  }
  return apiEndpoint + route;
}
