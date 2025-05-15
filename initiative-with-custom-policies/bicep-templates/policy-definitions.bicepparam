using './policy-definitions.bicep'

param policyFiles = [
  loadJsonContent('../policy-definitions/definition.function.app.https.only.json')
  loadJsonContent('../policy-definitions/definition.resource.lock.rgs.json')
]
