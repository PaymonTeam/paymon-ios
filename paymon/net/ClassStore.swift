//
// Created by Vladislav on 20/08/2017.
// Copyright (c) 2017 Paymon. All rights reserved.
//

import Foundation

class ClassStore {
    public static func deserialize(stream:SerializedBuffer_Wrapper, svuid:Int32, error:inout Bool) -> Packet? {
        var object:Packet
        switch (svuid) {
        case RPC.PM_error.svuid:
            object = RPC.PM_error();
        case RPC.PM_auth.svuid:
            object = RPC.PM_auth();
        case RPC.PM_authToken.svuid:
            object = RPC.PM_authToken();
        case RPC.PM_message.svuid:
            object = RPC.PM_message();
        case RPC.PM_messageItem.svuid:
            object = RPC.PM_messageItem();
        case RPC.PM_keepAlive.svuid:
            object = RPC.PM_keepAlive();
        case RPC.PM_chatMessages.svuid:
            object = RPC.PM_chatMessages();
        case RPC.PM_chatsAndMessages.svuid:
            object = RPC.PM_chatsAndMessages();
        case RPC.Group.svuid:
            object = RPC.Group();
        case RPC.PM_register.svuid:
            object = RPC.PM_register();
        case RPC.PM_searchContact.svuid:
            object = RPC.PM_searchContact();
        case RPC.PM_users.svuid:
            object = RPC.PM_users();
        case RPC.PM_user.svuid:
            object = RPC.PM_user();
        case RPC.PM_userFull.svuid:
            object = RPC.PM_userFull();
        case RPC.PM_addFriend.svuid:
            object = RPC.PM_addFriend();
        case RPC.PM_DHParams.svuid:
            object = RPC.PM_DHParams();
        case RPC.PM_requestDHParams.svuid:
            object = RPC.PM_requestDHParams();
        case RPC.PM_serverDHdata.svuid:
            object = RPC.PM_serverDHdata();
        case RPC.PM_clientDHdata.svuid:
            object = RPC.PM_clientDHdata();
        case RPC.PM_DHresult.svuid:
            object = RPC.PM_DHresult();
        case RPC.PM_postConnectionData.svuid:
            object = RPC.PM_postConnectionData();
        case RPC.PM_updateMessageID.svuid:
            object = RPC.PM_updateMessageID();
        case RPC.PM_photo.svuid:
            object = RPC.PM_photo();
        case RPC.PM_requestPhoto.svuid:
            object = RPC.PM_requestPhoto();
        case RPC.PM_updatePhotoID.svuid:
            object = RPC.PM_updatePhotoID();
        case RPC.PM_file.svuid:
            object = RPC.PM_file();
        case RPC.PM_filePart.svuid:
            object = RPC.PM_filePart();
        case RPC.PM_boolTrue.svuid:
            object = RPC.PM_boolTrue();
        case RPC.PM_boolFalse.svuid:
            object = RPC.PM_boolFalse();
        case RPC.PM_setProfilePhoto.svuid:
            object = RPC.PM_setProfilePhoto();
        case RPC.PM_getChatMessages.svuid:
            object = RPC.PM_getChatMessages();
        case RPC.PM_getStickerPack.svuid:
            object = RPC.PM_getStickerPack();
        case RPC.PM_stickerPack.svuid:
            object = RPC.PM_stickerPack();
        case RPC.PM_sticker.svuid:
            object = RPC.PM_sticker();
        case RPC.PM_BTC_getWalletKey.svuid:
            object = RPC.PM_BTC_getWalletKey();
        case RPC.PM_BTC_setWalletKey.svuid:
            object = RPC.PM_BTC_setWalletKey();
        case RPC.PM_ETC_getWalletKey.svuid:
            object = RPC.PM_ETC_getWalletKey();
        case RPC.PM_ETC_setWalletKey.svuid:
            object = RPC.PM_ETC_setWalletKey();
        case RPC.PM_resendEmail.svuid:
            object = RPC.PM_resendEmail();
        case RPC.PM_createGroup.svuid:
            object = RPC.PM_createGroup();
        case RPC.PM_group_addParticipants.svuid:
            object = RPC.PM_group_addParticipants();
        case RPC.PM_group_removeParticipant.svuid:
            object = RPC.PM_group_removeParticipant();
        case RPC.PM_group_setPhoto.svuid:
            object = RPC.PM_group_setPhoto();
        case RPC.PM_group_setSettings.svuid:
            object = RPC.PM_group_setSettings();
        case RPC.PM_ETH_balanceInfo.svuid:
            object = RPC.PM_ETH_balanceInfo();
        case RPC.PM_ETH_createWallet.svuid:
            object = RPC.PM_ETH_createWallet();
        case RPC.PM_ETH_fiatInfo.svuid:
            object = RPC.PM_ETH_fiatInfo();
        case RPC.PM_ETH_getBalance.svuid:
            object = RPC.PM_ETH_getBalance();
        case RPC.PM_ETH_getPublicFromPrivate.svuid:
            object = RPC.PM_ETH_getPublicFromPrivate();
        case RPC.PM_ETH_getTxInfo.svuid:
            object = RPC.PM_ETH_getTxInfo();
        case RPC.PM_ETH_publicFromPrivateInfo.svuid:
            object = RPC.PM_ETH_publicFromPrivateInfo();
        case RPC.PM_ETH_send.svuid:
            object = RPC.PM_ETH_send();
        case RPC.PM_ETH_sendInfo.svuid:
            object = RPC.PM_ETH_sendInfo();
        case RPC.PM_ETH_toFiat.svuid:
            object = RPC.PM_ETH_toFiat();
        case RPC.PM_ETH_txInfo.svuid:
            object = RPC.PM_ETH_txInfo();
        case RPC.PM_ETH_walletInfo.svuid:
            object = RPC.PM_ETH_walletInfo();
        case RPC.PM_exit.svuid:
            object = RPC.PM_exit();
        case RPC.PM_postReferal.svuid:
            object = RPC.PM_postReferal();
        default:
            return nil;
        }
        object.readParams(stream: stream, exception: &error);
        return object;
    }
}
