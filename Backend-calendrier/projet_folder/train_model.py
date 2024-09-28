from transformers import BartForConditionalGeneration, BartTokenizer
import torch
from torch.utils.data import Dataset, DataLoader
from sklearn.model_selection import train_test_split
import joblib

class TaskDurationDataset(Dataset):
    def __init__(self, tasks):
        self.tasks = tasks
        self.durations = torch.tensor([task['duration'] for task in tasks], dtype=torch.float)

    def __len__(self):
        return len(self.tasks)

    def __getitem__(self, idx):
        return {
            'task_description': self.tasks[idx]['task_description'],
            'duration': self.durations[idx]
        }

def fetch_data():
    tasks = [
        {'task_description': "Design database structure using MySQL.", 'duration': 15},
        {'task_description': "Create user-friendly and aesthetic UI using HTML, CSS, and JavaScript.", 'duration': 20},
        {'task_description': "Implement main application functionalities including user authentication and data management.", 'duration': 30},
        {'task_description': "Perform comprehensive testing to ensure the application functions correctly and fix any bugs.", 'duration': 25},
        {'task_description': "Deploy the application on production servers and configure the runtime environment.", 'duration': 22.5},
        {'task_description': "Provide continuous technical support to users and perform regular maintenance updates.", 'duration': 37.5},
        {'task_description': "Collect and analyze user requirements.", 'duration': 10},
        {'task_description': "Design and implement database architectures.", 'duration': 18.75},
        {'task_description': "Create responsive and visually appealing user interfaces.", 'duration': 16.25},
        {'task_description': "Develop backend functionalities using Python and Django.", 'duration': 27.5},
        {'task_description': "Test software components and fix bugs.", 'duration': 17.5},
        {'task_description': "Deploy applications to cloud platforms like AWS or Azure.", 'duration': 21.25},
        {'task_description': "Provide ongoing technical support and maintenance.", 'duration': 26.25},
        {'task_description': "Meet with stakeholders to discuss project requirements.", 'duration': 11.25},
        {'task_description': "Document project specifications and progress reports.", 'duration': 13.75},
        {'task_description': "Optimize application performance.", 'duration': 12.5},
        {'task_description': "Develop and update mobile applications.", 'duration': 22.5},
        {'task_description': "Ensure security compliance for all implemented features.", 'duration': 23.75},
        {'task_description': "Integrate third-party services like payment gateways.", 'duration': 20},
        {'task_description': "Conduct scalability tests to manage more users.", 'duration': 17.5},
        {'task_description': "Optimize database queries for improved performance.", 'duration': 14.25},
        {'task_description': "Implement real-time data processing with Apache Kafka.", 'duration': 32},
        {'task_description': "Enhance application security with OAuth and JWT.", 'duration': 18.5},
        {'task_description': "Automate deployment process using Jenkins and Docker.", 'duration': 26},
        {'task_description': "Refactor legacy code to improve maintainability.", 'duration': 19.75},
        {'task_description': "Develop a chatbot for customer service using AI.", 'duration': 21},
        {'task_description': "Upgrade system infrastructure to support increased traffic.", 'duration': 30.5},
        {'task_description': "Implement end-to-end encryption for data security.", 'duration': 29},
        {'task_description': "Conduct user experience research to enhance product design.", 'duration': 24},
        {'task_description': "Create a multi-language support system for global users.", 'duration': 22},
        {'task_description': "Optimize server response times through advanced caching mechanisms.", 'duration': 16},
        {'task_description': "Develop new features for data visualization in the platform.", 'duration': 28},
        {'task_description': "Integrate advanced machine learning models to predict user behavior.", 'duration': 35},
        {'task_description': "Create automated scripts for database backup and recovery procedures.", 'duration': 18},
        {'task_description': "Conduct thorough security audits to identify potential vulnerabilities.", 'duration': 26},
        {'task_description': "Design and implement APIs for third-party data integration.", 'duration': 21},
        {'task_description': "Organize and lead sprint planning meetings to define sprint goals and tasks.", 'duration': 8},
        {'task_description': "Draft detailed functional specifications for a new user authentication system.", 'duration': 12},
        {'task_description': "Design a scalable microservices architecture for a cloud-based application.", 'duration': 34},
        {'task_description': "Code a RESTful API to manage e-commerce transactions.", 'duration': 25},
        {'task_description': "Implement complex business logic for a financial processing system.", 'duration': 40},
        {'task_description': "Develop a real-time data synchronization system using WebSocket.", 'duration': 32},
        {'task_description': "Design and execute load testing scripts to validate system performance under peak loads.", 'duration': 20},
        {'task_description': "Automate regression tests using Selenium for a newly developed web application.", 'duration': 15},
        {'task_description': "Conduct accessibility compliance testing across major browsers.", 'duration': 18},
        {'task_description': "Roll out a CI/CD pipeline using GitLab for automated deployments.", 'duration': 27},
        {'task_description': "Monitor and optimize cloud infrastructure costs on AWS.", 'duration': 22},
        {'task_description': "Perform database migrations with zero downtime during a critical system upgrade.", 'duration': 24},
        {'task_description': "Troubleshoot and resolve critical server outages affecting user base.", 'duration': 16},
        {'task_description': "Update legacy software systems to comply with new data protection regulations.", 'duration': 30},
        {'task_description': "Provide detailed documentation and training to end-users on new software features.", 'duration': 14},
        {'task_description': "Implement and verify secure coding practices to prevent SQL injection attacks.", 'duration': 25},
        {'task_description': "Audit and update security protocols for third-party API integrations.", 'duration': 28},
        {'task_description': "Conduct a comprehensive review of network security infrastructure.", 'duration': 35},
        {'task_description': "Build interactive data visualization tools using D3.js for a marketing analytics dashboard.", 'duration': 26.5},
        {'task_description': "Redesign user interface for mobile adaptation of a web application to improve user engagement.", 'duration': 22},
        {'task_description': "Implement adaptive loading for a performance-optimized user experience in a web app.", 'duration': 18},
        {'task_description': "Develop a custom content management system in Node.js with MongoDB integration.", 'duration': 35},
        {'task_description': "Set up a secure OAuth2 server for mobile and web client authentication.", 'duration': 30},
        {'task_description': "Integrate a third-party CRM system with existing enterprise sales applications.", 'duration': 28},
        {'task_description': "Design and deploy a Kubernetes cluster for container orchestration of microservices.", 'duration': 40},
        {'task_description': "Automate nightly build processes using Jenkins to streamline development cycles.", 'duration': 16},
        {'task_description': "Configure and manage a multi-tenant cloud environment using AWS services.", 'duration': 32},
        {'task_description': "Develop machine learning models to predict customer churn based on user activity data.", 'duration': 38},
        {'task_description': "Clean, preprocess, and analyze large datasets using Python pandas for market trend analysis.", 'duration': 25},
        {'task_description': "Implement a recommendation system for an e-commerce platform using collaborative filtering.", 'duration': 29},
        {'task_description': "Perform vulnerability assessments and penetration testing for a financial application.", 'duration': 31},
        {'task_description': "Develop and implement data encryption standards to secure sensitive customer information.", 'duration': 24},
        {'task_description': "Setup and maintain firewall configurations to protect internal networks from external threats.", 'duration': 21},
        {'task_description': "Coordinate with multiple stakeholders to deliver a major software update.", 'duration': 15},
        {'task_description': "Manage software deployment project from planning to execution and post-launch support.", 'duration': 28},
        {'task_description': "Lead a team of developers and designers in a cross-functional project using Agile methodologies.", 'duration': 34},
        {'task_description': "Prototype a new augmented reality feature for a mobile app to enhance user interaction.", 'duration': 27},
        {'task_description': "Develop a cross-platform app using Flutter to streamline operations for field service technicians.", 'duration': 33},
        {'task_description': "Create a voice recognition feature to add hands-free operation to an existing application.", 'duration': 25},
        {'task_description': "Automate manual data entry processes with a custom Python script that interfaces with database APIs.", 'duration': 17},
        {'task_description': "Develop a script to automate the migration of legacy data to a new platform.", 'duration': 20},
        {'task_description': "Implement an automated error reporting system for a large-scale web application.", 'duration': 22},
        {'task_description': "Establish a set of security protocols for remote access to company servers.", 'duration': 18},
        {'task_description': "Resolve and mitigate a series of DDoS attacks affecting company infrastructure.", 'duration': 26},
        {'task_description': "Implement a network segmentation strategy to enhance security and performance.", 'duration': 31},
        {'task_description': "Conduct research on blockchain technology to explore potential applications in secure transactions.", 'duration': 35},
        {'task_description': "Experiment with machine learning techniques to optimize search algorithms for an online retailer.", 'duration': 29},
        {'task_description': "Investigate the feasibility of using biometric data for advanced user authentication systems.", 'duration': 32},
        {'task_description': "Refine SQL database queries to reduce load times by 50 percent for a high-traffic application.", 'duration': 14},
        {'task_description': "Optimize the performance of a server cluster by tuning configuration and load balancing strategies.", 'duration': 24},
        {'task_description': "Scale a mobile application to handle an expected increase of a million new users.", 'duration': 28},
        {'task_description': "Design and conduct a series of workshops on cybersecurity best practices for new employees.", 'duration': 12},
        {'task_description': "Develop a comprehensive onboarding program for developers that includes a mix of training on software tools and company culture.", 'duration': 19},
        {'task_description': "Create a continuous learning environment that encourages innovation through regular tech talks and hackathons.", 'duration': 21}
    ]
    return tasks


tasks = fetch_data()
dataset = TaskDurationDataset(tasks)
train_data, test_data = train_test_split(dataset, test_size=0.1, random_state=42)
train_loader = DataLoader(train_data, batch_size=1, shuffle=True)
test_loader = DataLoader(test_data, batch_size=1)

model = BartForConditionalGeneration.from_pretrained("facebook/bart-base")
tokenizer = BartTokenizer.from_pretrained("facebook/bart-base")

num_epochs = 5
learning_rate = 1e-4
optimizer = torch.optim.AdamW(model.parameters(), lr=learning_rate)
criterion = torch.nn.MSELoss()

def predict_task_duration(model, tokenizer, task_description):
    inputs = tokenizer(task_description, return_tensors="pt", padding=True, truncation=True, max_length=64)
    outputs = model(**inputs)
    logits = outputs.logits
    predicted_duration = logits[:, -1].mean(dim=-1)
    return predicted_duration

model.train()
for epoch in range(num_epochs):
    total_loss = 0
    for batch in train_loader:
        optimizer.zero_grad()
        task_description = batch['task_description']
        actual_duration = batch['duration']
        predicted_duration = predict_task_duration(model, tokenizer, task_description)
        loss = criterion(predicted_duration, actual_duration)
        loss.backward()
        optimizer.step()
        total_loss += loss.item()

    print(f"Epoch {epoch+1}, Average Loss: {total_loss / len(train_loader)}")

model.eval()
test_loss = 0
with torch.no_grad():
    for batch in test_loader:
        task_description = batch['task_description']
        actual_duration = batch['duration']
        predicted_duration = predict_task_duration(model, tokenizer, task_description)
        loss = criterion(predicted_duration, actual_duration)
        test_loss += loss.item()

    print("Test Loss:", test_loss / len(test_loader))

joblib.dump(model, "saved_model.joblib")
joblib.dump(tokenizer, "tokenizer.joblib")
