function calculateIMC() {
    var altura =  document.getElementById('altura').value;
    var peso = document.getElementById('peso').value;


    var result;
    if (!peso || !altura) {
        result = "Peso e/ou altura não preenchido";
        return;
    }

    var imc = peso / Math.pow(altura, 2);
    if (imc < 18.5) {
        result =imc.toFixed(2) + " Magreza";
    } else if (imc >= 18.5 && imc < 24.9) {
        result =imc.toFixed(2) + " Normal";
    } else if (imc >= 24.9 && imc < 30) {
        result =imc.toFixed(2) + " Sobrepeso";
    } else {
        result =imc.toFixed(2) + " Obesidade";
    }

    return result
}

function setResultOnHTML() {
var resultadoDoCalculo = calculateIMC()

    document.querySelector('#result p')
    .innerHTML = resultadoDoCalculo

}