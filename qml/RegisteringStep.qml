import QtQuick 2.0
import QtQuick.Layouts 1.0
import QtQuick.Controls 1.1
import QtQuick.Controls.Styles 1.3
import org.ethereum.qml.QEther 1.0
import Qt.labs.settings 1.0
import "js/TransactionHelper.js" as TransactionHelper
import "js/NetworkDeployment.js" as NetworkDeploymentCode
import "js/QEtherHelper.js" as QEtherHelper
import "."

Rectangle {
	property variant worker
	property string eth: registrarAddr.text
	property int ownedRegistrarDeployGas: 1179075 // TODO: Use sol library to calculate gas requirement for each tr.
	property int ownedRegistrarSetSubRegistrarGas: 50000
	property int ownedRegistrarSetContentHashGas: 50000
	property int urlHintSuggestUrlGas: 70000
	id: root
	color: "#E3E3E3E3"
	anchors.fill: parent
	signal registered

	function show()
	{
		ctrRegisterLabel.calculateRegisterGas()
		if (applicationUrlHttpCtrl.text === "")
			applicationUrlHttpCtrl.text = projectModel.applicationUrlHttp

		if (applicationUrlEthCtrl.text === "")
			applicationUrlEthCtrl.text = projectModel.applicationUrlEth

		visible = true

		worker.pooler.onTriggered.connect(function() {
			if (root.visible)
				verifyRegistering();
		})
	}

	function verifyRegistering()
	{
		verificationEthUrl.text = ""
		if (projectModel.registerContentHashTrHash !== "" && projectModel.registerContentHashBlockNumber !== -1)
		{
			worker.verifyHash("registerHash", projectModel.registerContentHashTrHash, function(bn, trLost)
			{
				updateVerification(projectModel.registerContentHashBlockNumber, bn, trLost, verificationEthUrl, "registerHash")
			});
		}
		else if (projectModel.registerContentHashTrHash !== "" && projectModel.registerContentHashBlockNumber === -1)
			verificationEthUrl.text = qsTr("waiting verifications")

		verificationUrl.text = ""
		if (projectModel.registerUrlTrHash !== "" && projectModel.registerUrlBlockNumber !== -1)
		{
			worker.verifyHash("registerUrl", projectModel.registerUrlTrHash, function(bn, trLost)
			{
				updateVerification(projectModel.registerUrlBlockNumber, bn, trLost, verificationUrl, "registerUrl")
			});
		}
		else if (projectModel.registerUrlTrHash !== "" && projectModel.registerUrlBlockNumber === -1)
			verificationUrl.text = qsTr("waiting verifications")
	}

	function updateVerification(originbn, bn, trLost, ctrl, trContext)
	{
		if (trLost.length === 0)
		{
			ctrl.text = bn - originbn
			if (parseInt(bn - originbn) >= 10)
			{
				ctrl.color= "green"
				ctrl.text= qsTr("verified")
			}
			else
				ctrl.text += qsTr(" verifications")
		}
		else
		{
			deploymentStepChanged(trContext + qsTr(" has been invalidated.") + trLost[0] + " " + qsTr("no longer present") )
			ctrl.text = qsTr("invalidated")
		}
	}

	ColumnLayout
	{
		anchors.top: parent.top
		anchors.topMargin: 10
		id: col
		spacing: 20
		anchors.left: parent.left
		anchors.leftMargin: 10
		width: parent.width
		DefaultLabel
		{
			anchors.top: parent.top
			Layout.preferredWidth: 300
			text: qsTr("Register the internet and Ethereum URL of your dapp on name registrar to make it easily accesible to users.")
			font.bold: true
		}

		DefaultLabel
		{
			Layout.preferredWidth: 300
			text: qsTr("The name Registrar must have been already deployed on the main chain.")
			font.bold: true
		}

		RowLayout
		{
			Layout.fillWidth: true
			Layout.minimumHeight: 20
			Rectangle
			{
				Layout.preferredWidth: col.width / 5
				DefaultLabel
				{
					text: qsTr("Root Registrar address")
					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
				}
			}

			DefaultTextField
			{
				id: registrarAddr
				text: "c6d9d2cd449a754c494264e1809c50e34d64562b"
				visible: true
				Layout.preferredWidth: 450
			}
		}

		Connections
		{
			target: worker
			onNodeUnreachable:
			{
				registerDappBtn.enabled = false
			}
			onNodeReachable:
			{
				registerDappBtn.enabled = true
			}
		}

		RowLayout
		{
			Layout.fillWidth: true
			Layout.minimumHeight: 20
			Rectangle
			{
				Layout.preferredWidth: col.width / 5
				DefaultLabel
				{
					text: qsTr("Http URL")
					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
					id: httpurlLabel
				}

				DefaultLabel
				{
					text: qsTr("(pastebin url or similar)")
					anchors.verticalCenter: parent.verticalCenter
					anchors.top: httpurlLabel.bottom
					anchors.topMargin: 2
					anchors.left: httpurlLabel.left
					anchors.leftMargin: 15
				}
			}

			DefaultTextField
			{
				id: applicationUrlHttpCtrl
				Layout.preferredWidth: 450
			}

			DefaultLabel
			{
				id: verificationUrl
				anchors.verticalCenter: parent.verticalCenter
				font.italic: true
			}
		}		

		RowLayout
		{
			Layout.fillWidth: true
			Layout.minimumHeight: 20
			Rectangle
			{
				Layout.preferredWidth: col.width / 5
				DefaultLabel
				{
					text: qsTr("Ethereum URL")
					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
				}
			}

			Rectangle
			{
				height: 25
				color: "transparent"
				Layout.preferredWidth: 450
				DefaultTextField
				{
					width: 450
					id: applicationUrlEthCtrl
					onTextChanged: {
						ctrRegisterLabel.calculateRegisterGas();
					}
				}
			}
		}

		RowLayout
		{
			Layout.fillWidth: true
			Layout.minimumHeight: 20
			Rectangle
			{
				Layout.preferredWidth: col.width / 4
				DefaultLabel
				{
					text: qsTr("Formatted Ethereum URL")
					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
				}
			}

			DefaultLabel
			{
				id: appUrlFormatted
				anchors.verticalCenter: parent.verticalCenter;
				anchors.topMargin: 10
				font.italic: true
			}

			DefaultLabel
			{
				id: verificationEthUrl
				anchors.verticalCenter: parent.verticalCenter;
				anchors.topMargin: 10
				font.italic: true
			}
		}

		RowLayout
		{
			Layout.fillWidth: true
			Rectangle
			{
				Layout.preferredWidth: col.width / 5
				DefaultLabel
				{
					text: qsTr("Gas price")
					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
				}
			}

			Item
			{
				Layout.preferredWidth: 450
				Layout.minimumHeight: 60
				GasPrice
				{
					id: gasPriceConf
					onGasPriceChanged: ctrRegisterLabel.calculateRegisterGas()
					defaultGasPrice: true
					width: parent.width
				}
			}

			Connections
			{
				target: worker
				id: gasPriceLoad
				onGasPriceLoaded:
				{
					gasPriceConf.init(worker.gasPriceInt.value())
					ctrRegisterLabel.calculateRegisterGas()
				}
			}
		}

		RowLayout
		{
			Layout.fillWidth: true
			Layout.minimumHeight: 20
			Rectangle
			{
				Layout.preferredWidth: col.width / 5
				DefaultLabel
				{
					text: qsTr("Registration Cost")
					anchors.left: parent.left
					anchors.verticalCenter: parent.verticalCenter
					id: ctrRegisterLabel
					function calculateRegisterGas()
					{
						if (!modalDeploymentDialog.visible)
							return;
						appUrlFormatted.text = NetworkDeploymentCode.formatAppUrl(applicationUrlEthCtrl.text).join('/');
						NetworkDeploymentCode.checkPathCreationCost(applicationUrlEthCtrl.text, function(pathCreationCost)
						{
							var ether = QEtherHelper.createBigInt(pathCreationCost);
							if (gasPriceConf.gasPrice)
							{
								var gasTotal = ether.multiply(gasPriceConf.gasPrice.toWei());
								gasToUseDeployInput.value = QEtherHelper.createEther(gasTotal.value(), QEther.Wei, parent);
								gasToUseDeployInput.update();
							}
						});
					}
				}
			}

			Ether
			{
				id: gasToUseDeployInput
				displayUnitSelection: false
				displayFormattedValue: true
				edit: false
				Layout.preferredWidth: 235
			}
		}
	}

	RowLayout
	{
		anchors.bottom: parent.bottom
		anchors.bottomMargin: 10
		width: parent.width

		function registerHash(gasPrice, callback)
		{
			var inError = [];
			var ethUrl = NetworkDeploymentCode.formatAppUrl(applicationUrlEthCtrl.text);
			for (var k in ethUrl)
			{
				if (ethUrl[k].length > 32)
					inError.push(qsTr("Member too long: " + ethUrl[k]) + "\n");
			}
			if (!worker.stopForInputError(inError))
			{
				NetworkDeploymentCode.registerDapp(ethUrl, gasPrice,  function(){
					projectModel.applicationUrlEth = applicationUrlEthCtrl.text
					projectModel.saveProject()
					verificationEthUrl.text = qsTr("waiting verifications")
					worker.waitForTrReceipt(projectModel.registerContentHashTrHash, function(status, receipt)
					{
						worker.verifyHash("registerHash", projectModel.registerContentHashTrHash, function(bn, trLost)
						{
							projectModel.registerContentHashBlockNumber = bn
							projectModel.saveProject()
							root.updateVerification(bn, bn, trLost, verificationEthUrl)
							callback()
						});
					});
				})
			}
		}

		function registerUrl(gasPrice, callback)
		{
			if (applicationUrlHttp.text === "" || deploymentDialog.packageHash === "")
			{
				deployDialog.title = text;
				deployDialog.text = qsTr("Please provide the link where the resources are stored and ensure the package is aleary built using the deployment step.")
				deployDialog.open();
				return;
			}
			var inError = [];
			if (applicationUrlHttpCtrl.text.length > 32)
				inError.push(qsTr(applicationUrlHttpCtrl.text));
			if (!worker.stopForInputError(inError))
			{
				var url = applicationUrlHttpCtrl.text
				url = url.replace("http://", "").replace("https://", "")
				registerToUrlHint(url, gasPrice, function(){
					projectModel.applicationUrlHttp = applicationUrlHttpCtrl.text
					projectModel.saveProject()
					verificationUrl.text = qsTr("waiting verifications")
					worker.waitForTrReceipt(projectModel.registerUrlTrHash, function(status, receipt)
					{
						worker.verifyHash("registerUrl", projectModel.registerUrlTrHash, function(bn, trLost)
						{
							projectModel.registerUrlBlockNumber = bn
							projectModel.saveProject()
							root.updateVerification(bn, bn, trLost, verificationUrl)
							root.registered()
							callback()
						});
					})
				})
			}
		}

		DefaultButton
		{
			anchors.right: parent.right
			anchors.rightMargin: 10
			text: qsTr("Register Dapp")
			id: registerDappBtn
			width: 30
			onClicked:
			{
				verificationEthUrl.text = ""
				verificationUrl.text = ""
				projectModel.cleanRegisteringStatus()
				parent.registerHash(gasPriceConf.gasPrice, function(){
					parent.registerUrl(gasPriceConf.gasPrice, function(){})
				})
			}
			enabled: applicationUrlEthCtrl.text != "" && applicationUrlHttpCtrl.text != "" && registrarAddr.text != "" && registrarAddr.text.length === 40
		}
	}
}

