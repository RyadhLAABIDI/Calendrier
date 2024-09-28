import express from 'express';
import mongoose from 'mongoose';
import cors from 'cors';
import morgan from 'morgan';
import don from './routes/planningRoute.js';
import { errorHandler } from './Middllewares/error-handler.js';

const app = express();
const port = process.env.PORT || 3000;
const databaseName = 'fakeDataDB';

mongoose.set('debug', true);

mongoose.Promise = global.Promise;
// Se connecter à MongoDB
mongoose
  .connect(`mongodb://localhost:27017/${databaseName}`)
  .then(() => {
    console.log(`Connected to MongoDB`);
  })
  .catch(err => {
    console.log(err);
  });

// Middleware pour activer CORS
app.use(cors());
// #### morgan
app.use(morgan('dev'));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));
app.use(errorHandler);

// Routes 
app.use('/don', don);

// Middleware personnalisé pour la gestion des erreurs 
app.use((error, req, res, next) => {
  res.status(error.status || 500).json({
    message: error.message || 'Internal Server Error',
  });
});

// Démarrage du serveur en écoutant sur toutes les interfaces réseau disponibles
app.listen(port, () => {
  console.log(`Le serveur écoute sur le port ${port}`);
});
