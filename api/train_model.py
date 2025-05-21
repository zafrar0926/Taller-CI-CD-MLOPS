# Niveles/4/api/train_model.py
from sklearn.datasets import load_iris
from sklearn.ensemble import RandomForestClassifier
from sklearn.model_selection import train_test_split
import pickle

# Cargar dataset
X, y = load_iris(return_X_y=True)
X_train, _, y_train, _ = train_test_split(X, y, test_size=0.2, random_state=42)

# Entrenar modelo
model = RandomForestClassifier()
model.fit(X_train, y_train)

# Guardar modelo
with open("app/model.pkl", "wb") as f:
    pickle.dump(model, f)
