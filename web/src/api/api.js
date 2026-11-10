import axios from 'axios';

const API = axios.create({
  baseURL: import.meta.env.VITE_API_URL || 'http://localhost:5000'
});

// Interceptor tự động gán JWT token vào header
API.interceptors.request.use(cfg => {
  const token = localStorage.getItem('adminToken');
  if (token) cfg.headers.Authorization = `Bearer ${token}`;
  return cfg;
});

export default API;
