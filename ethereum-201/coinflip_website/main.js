var web3 = new Web3(Web3.givenProvider);
var contractInstance;
var useraddress;
var blockNumber

$(document).ready(function() {
    window.ethereum.enable().then(function(accounts){
      contractInstance = new web3.eth.Contract(window.abi, "0x80cae3Cd137C9157Bbee249ef1859fd20aeF8250", {from: accounts[0]});
      console.log(contractInstance);
      contractInstance.methods.balance().call().then(function(res){
        $("#balance_output").text(web3.utils.fromWei(res, "ether"));
        console.log(res);
      })

      contractInstance.methods.balance_available().call().then(function(res){
        $("#balance_available_output").text(web3.utils.fromWei(res, "ether"));
        console.log(res);
      })

});

getAccounts(function(result) {
   useraddress = result[0];
    console.log(result[0]);
});




$("#bet_heads_button").click(inputDataHeads)
$("#bet_tails_button").click(inputDataTails)
$("#get_button").click(fetchData)
$("#withdraw_button").click(withdraw)

function getAccounts(callback) {
    web3.eth.getAccounts((error,result) => {
        if (error) {
            console.log(error);
        } else {
            callback(result);
        }
    });
}

function inputData(betside){
  var betsize = $("#betsize_input").val();

  var config = {
      value: web3.utils.toWei(betsize, "ether")
  }

  contractInstance.methods.flip(betside).send(config)
  .on("transactionHash", function(hash){
    console.log(hash);
  })
  .on("confirmation", function(confirmationNr){
    console.log(confirmationNr);
  })
  .on("receipt", function(receipt){
    console.log(receipt);


    contractInstance.once("FlipResult", {
        filter: {player: useraddress},
        fromBlock: 'latest'
    }, function(error, event){
      console.log(event);
      alert("It's ".concat(event.returnValues.coinside).concat("! You ").concat(event.returnValues.betresult).concat(" ").concat(betsize).concat(" ETH."));

    })
  })
}

function inputDataHeads(){
  inputData("Heads");
}

function inputDataTails(){
  inputData("Tails");
}

function fetchData(){
  contractInstance.methods.getResult().call().then(function(res){
    $("#coinresult_output").text(res[0]);
    $("#betresult_output").text(res[1]);
  })

  contractInstance.methods.balance().call().then(function(res){
      $("#balance_output").text(web3.utils.fromWei(res, "ether"));
      })

  contractInstance.methods.balance_available().call().then(function(res){
      $("#balance_available_output").text(web3.utils.fromWei(res, "ether"));
      console.log(res);
    })

  contractInstance.methods.getPotBalance().call().then(function(res){
      $("#user_potbalance").text(web3.utils.fromWei(res, "ether"));
    })

}


function withdraw(){
  var withdrawAmount = web3.utils.toWei($("#withdraw_input").val(), "ether");
  console.log(withdrawAmount);
  contractInstance.methods.withdrawFromPot(withdrawAmount).send();
  alert("sending amount: ".concat($("#withdraw_input").val()).concat(" ETH"));
}

});
