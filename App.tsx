import React from 'react';
import { StatusBar } from 'expo-status-bar';
import { Provider } from 'react-redux';
import { PersistGate } from 'redux-persist/integration/react';
import { NavigationContainer } from '@react-navigation/native';
import { store, persistor } from './src/store/store';
import MainNavigator from './src/navigation/MainNavigator';
import { ThemeProvider } from './src/contexts/ThemeContext';
import { LoadAssets } from './src/components/common/LoadAssets';

export default function App() {
  return (
    <Provider store={store}>
      <PersistGate loading={null} persistor={persistor}>
        <ThemeProvider>
          <LoadAssets>
            <NavigationContainer>
              <StatusBar style="auto" />
              <MainNavigator />
            </NavigationContainer>
          </LoadAssets>
        </ThemeProvider>
      </PersistGate>
    </Provider>
  );
}