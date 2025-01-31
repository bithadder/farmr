import 'package:farmr_client/blockchain.dart';
import 'package:farmr_client/wallets/coldWallets/coldwallet.dart';
import 'package:http/http.dart' as http;
import 'package:logging/logging.dart';

Logger log = Logger("Chia Explorer Cold Wallet");

class FlaxExplorerWallet extends ColdWallet {
  final String address;
  static const String _flaxExplorerURL =
      "https://flaxexplorer.org/blockchain/address/";

  FlaxExplorerWallet(
      {required Blockchain blockchain,
      required this.address,
      int syncedBlockHeight = -1,
      String name = "FlaxExplorer Cold Wallet"})
      : super(
            blockchain: blockchain,
            syncedBlockHeight: syncedBlockHeight,
            name: name);

  Future<void> init() async {
    //flaxexplorer has no way to know if wallet is empty or address invalid
    // always start with net balance and farm balances 0
    netBalance = 0;
    farmedBalance = 0;

    String contents = await http.read(Uri.parse(_flaxExplorerURL + address));

    RegExp regex = RegExp(r"([0-9]+\.[0-9]+) XFX</span>", multiLine: true);

    try {
      var matches = regex.allMatches(contents);

      if (matches.length == 2) {
        netBalance =
            ((double.tryParse(matches.elementAt(0).group(1) ?? "-1.0") ??
                        -1.0) *
                    blockchain.majorToMinorMultiplier)
                .round();
        farmedBalance =
            ((double.tryParse(matches.elementAt(1).group(1) ?? "-1.0") ??
                        -1.0) *
                    blockchain.majorToMinorMultiplier)
                .round();
      }
    } catch (error) {
      log.warning("Failed to get info about flax cold wallet balance");
    }

    //tries to parse last farmed  reward
    RegExp blockHeightExp = RegExp(
        r'farmer reward<\/td>[\s]+<td><a href="\/blockchain\/coin\/[\w]+">[\w]+<\/a><\/td>[\s]+<td>[0-9\.]+ xfx<\/td>[\s]+<td>([0-9]+)',
        multiLine: true);

    try {
      var blockHeightMatches =
          blockHeightExp.allMatches(contents.toLowerCase());
      if (blockHeightMatches.length > 0)
        setLastBlockFarmed(
            int.parse(blockHeightMatches.first.group(1) ?? "-1"));
    } catch (error) {
      log.warning("Failed to get info about cold wallet last farmed reward");
    }
  }
}
