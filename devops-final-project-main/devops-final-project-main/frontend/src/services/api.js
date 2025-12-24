import axios from 'axios';

const createApiClient = (baseURL) => {
  const client = axios.create({
    baseURL,
    headers: {
      'Content-Type': 'application/json',
    },
  });

  return client;
};

export const getNotes = async (baseURL) => {
  const client = createApiClient(baseURL);
  try {
    const response = await client.get('/notes');
    return response.data.notes || response.data || [];
  } catch (error) {
    console.error('Error fetching notes:', error);
    throw error;
  }
};

export const getNote = async (baseURL, id) => {
  const client = createApiClient(baseURL);
  try {
    const response = await client.get(`/notes/${id}`);
    return response.data;
  } catch (error) {
    console.error('Error fetching note:', error);
    throw error;
  }
};

export const createNote = async (baseURL, noteData) => {
  const client = createApiClient(baseURL);
  try {
    const response = await client.post('/notes', noteData);
    return response.data;
  } catch (error) {
    console.error('Error creating note:', error);
    throw error;
  }
};

export const updateNote = async (baseURL, id, noteData) => {
  const client = createApiClient(baseURL);
  try {
    const response = await client.put(`/notes/${id}`, noteData);
    return response.data;
  } catch (error) {
    console.error('Error updating note:', error);
    throw error;
  }
};

export const deleteNote = async (baseURL, id) => {
  const client = createApiClient(baseURL);
  try {
    await client.delete(`/notes/${id}`);
  } catch (error) {
    console.error('Error deleting note:', error);
    throw error;
  }
};

