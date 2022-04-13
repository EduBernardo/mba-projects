var messages = ['1','2','3','4'];

function pickMessage() {
    var nr = Math.random()
    var msgIndex = parseInt(nr * messages.length)
    var mensagem = messages[msgIndex];
    return mensagem;
}

function updateMessage() {
    document.querySelector('.letter p')
    .innerHTML = pickMessage();
}

window.onload = function() {
    updateMessage()
}