from bson import ObjectId
from datetime import datetime, timedelta
from flask import Flask, request, jsonify
from flask_cors import CORS
import joblib
import random
import logging
from pymongo import MongoClient
from train_model import predict_task_duration

app = Flask(__name__)
CORS(app)

# Configuration du logging
logging.basicConfig(level=logging.INFO)

# Connexion à MongoDB
client = MongoClient("mongodb://localhost:27017")
db = client.fakeDataDB

# Chargement du modèle et du tokenizer
try:
    model = joblib.load("saved_model.joblib")
    tokenizer = joblib.load("tokenizer.joblib")
    logging.info("Modèle et tokenizer chargés avec succès.")
except FileNotFoundError:
    logging.error("Fichier modèle ou tokenizer non trouvé.")
    raise
except Exception as e:
    logging.error(f"Erreur lors du chargement du modèle ou tokenizer: {e}")
    raise

def validate_model():
    test_description = "Validate model functionality."
    try:
        prediction = predict_task_duration(model, tokenizer, test_description)  # Ajout des arguments requis
        logging.info(f"Validation réussie, sortie de prédiction : {prediction}")
    except Exception as e:
        logging.error(f"Échec de la validation du modèle : {e}")

@app.route('/predict_task_duration/<string:project_id>', methods=['GET'])
def route_predict_task_duration(project_id):
    try:
        print("Requête reçue pour prédire les durées des tâches pour le projet ID:", project_id)
        project_id_obj = ObjectId(project_id)
        project = db.projects.find_one({'_id': project_id_obj})
        if project:
            print("Projet trouvé dans la base de données :", project)
            response = calculate_project_duration(project_id_obj)
            adjust_dates(response)  # Appel à la fonction pour ajuster les dates
            return jsonify(response), 200
        else:
            print("Aucun projet trouvé avec cet ID:", project_id_obj)
            return jsonify({'error': 'Aucun projet trouvé avec cet ID.'}), 404
    except Exception as e:
        print("Erreur lors de la prédiction :", e)
        return jsonify({'error': 'Une erreur est survenue lors de la prédiction.'}), 500

def calculate_project_duration(project_id_obj):
    project = db.projects.find_one({'_id': project_id_obj})
    startDate = project['startDate']
    endDate = project['endDate']
    total_project_duration = (endDate - startDate).days
    
    project_info = {
        'startDate': startDate.strftime('%Y-%m-%d'),
        'endDate': endDate.strftime('%Y-%m-%d'),
        'total_duration': total_project_duration,
        'keywords': project.get('keywords', []),
        'teamLeader': project.get('teamLeader', ''),
        'members': project.get('members', [])
    }
    
    response = {
        'project_info': project_info,
        'modules': []
    }
    total_predicted_duration = 0

    modules = db.modules.find({'projectID': project_id_obj})
    for module in modules:
        module_info = {'id': str(module['_id']), 'module_name': module['module_name'], 'teamM': module.get('teamM', []), 'total_duration': 0, 'tasks': []}
        tasks = db.tasks.find({'module_id': module['_id']})
        for task in tasks:
            task_info = calculate_task_duration(task)
            task_info['team'] = task.get('team', [])
            module_info['tasks'].append(task_info)
            module_info['total_duration'] += task_info['duration']
        total_predicted_duration += module_info['total_duration']
        response['modules'].append(module_info)

    if total_predicted_duration > 0:
        for module in response['modules']:
            for task in module['tasks']:
                length_factor = len(task['task_description']) / 100  # Modifié ici
                variability = random.uniform(0.9, 1.1)
                adjustment_factor = (total_project_duration / total_predicted_duration) * variability * length_factor
                task['duration'] = round(task['duration'] * adjustment_factor)
                module['total_duration'] = sum(task['duration'] for task in module['tasks'])

    new_total_project_duration = sum(module['total_duration'] for module in response['modules'])
    response['project_info']['total_duration'] = new_total_project_duration
    response['project_info']['endDate'] = (startDate + timedelta(days=new_total_project_duration)).strftime('%Y-%m-%d')

    return response

def calculate_task_duration(task):
    task_description = f"{task['task_description']} du projet"  # Modifié ici
    predicted_duration = get_predicted_duration(model, tokenizer, task_description)
    duration_in_days = round(predicted_duration / 24)
    return {'id': str(task['_id']), 'task_description': task_description, 'duration': duration_in_days, 'completed': task.get('completed', False)}

def get_predicted_duration(model, tokenizer, task_description):
    inputs = tokenizer(task_description, return_tensors="pt", padding=True, truncation=True, max_length=1021)
    outputs = model(**inputs)
    logits = outputs.logits
    predicted_duration = logits[:, -1].mean(dim=-1).item()
    return int(predicted_duration)

def adjust_dates(response):
    project_startDate = datetime.strptime(response['project_info']['startDate'], "%Y-%m-%d")
    for i, module in enumerate(response['modules']):
        start_date = project_startDate if i == 0 else datetime.strptime(response['modules'][i-1]['module_end_date'], "%Y-%m-%d")
        module_start_date = start_date.strftime("%Y-%m-%d")
        for task in module['tasks']:
            task_start_date = start_date.strftime("%Y-%m-%d")
            task_end_date = (start_date + timedelta(days=task['duration'])).strftime("%Y-%m-%d")
            task['startDate'] = task_start_date
            task['endDate'] = task_end_date
            start_date += timedelta(days=task['duration'])
        module['module_start_date'] = module_start_date
        module['module_end_date'] = start_date.strftime("%Y-%m-%d")

if __name__ == '__main__':
    app.run(debug=True, port=5001)
